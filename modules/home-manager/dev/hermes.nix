{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.hermes;
  homeDir =
    if config ? home && config.home ? homeDirectory then
      config.home.homeDirectory
    else
      config.users.users.${config.user.name}.home;

  hermesHome = "${homeDir}/.hermes";

  # Merge MCP servers into final settings
  mcpServerAttrs = mapAttrs (
    _name: srv:
    optionalAttrs (srv.command != null) { inherit (srv) command args; }
    // optionalAttrs (srv.env != { }) { inherit (srv) env; }
    // optionalAttrs (srv.url != null) { inherit (srv) url; }
    // optionalAttrs (srv.headers != { }) { inherit (srv) headers; }
    // optionalAttrs (srv.auth != null) { inherit (srv) auth; }
    // {
      inherit (srv) enabled;
    }
    // optionalAttrs (srv.timeout != null) { inherit (srv) timeout; }
    // optionalAttrs (srv.tools != null) {
      tools = filterAttrs (_: v: v != [ ]) {
        inherit (srv.tools) include exclude;
      };
    }
  ) cfg.mcpServers;

  finalSettings =
    cfg.settings // optionalAttrs (cfg.mcpServers != { }) { mcp_servers = mcpServerAttrs; };

  settingsJson = pkgs.writeText "hermes-settings.json" (builtins.toJSON finalSettings);

  # The llm-agents hermes-agent package is missing the `mcp` Python library
  # (the [mcp] extra isn't included in their build). The hermes Python wrapper
  # uses site.addsitedir() which ignores PYTHONPATH, so we patch the inner
  # Python script to include mcp and its deps in the site-packages list.
  hermesPkg =
    let
      base = pkgs.llm-agents.hermes-agent;
      py = pkgs.python313Packages;
      # mcp and deps not already bundled with hermes
      mcpDeps = [
        py.mcp
        py.sse-starlette
        py.uvicorn
        py.starlette
        py.pydantic-settings
        py.python-multipart
      ];
      mcpSiteArgs = concatMapStringsSep "," (dep: "'${dep}/lib/python3.13/site-packages'") mcpDeps;
    in
    pkgs.runCommand "hermes-agent-with-mcp"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        inherit (base) meta;
      }
      ''
        cp -rs ${base} $out
        chmod -R u+w $out/bin

        for name in hermes hermes-agent hermes-acp; do
          wrapper="$out/bin/$name"
          [ -f "$wrapper" ] || continue

          # Find the innermost Python script through the wrapper chain
          inner=$(${pkgs.gnugrep}/bin/grep -oP 'exec.*?"\K[^"]*\.hermes-wrapped' "$wrapper" || true)
          [ -z "$inner" ] && continue

          # Copy and patch the Python script to include mcp site-packages
          cp --remove-destination "$inner" "$out/bin/.$name-patched"
          chmod u+w "$out/bin/.$name-patched"
          ${pkgs.gnused}/bin/sed -i \
            "s|], site._init_pathinfo())|,${mcpSiteArgs}], site._init_pathinfo())|" \
            "$out/bin/.$name-patched"

          # Update the bash wrapper to use our patched script
          ${pkgs.gnused}/bin/sed -i "s|$inner|$out/bin/.$name-patched|" "$wrapper"
        done
      '';

  # Deep-merge script adapted from upstream nix/configMergeScript.nix.
  # Nix-declared keys win; user-added keys (skills, streaming, etc.) are preserved.
  configMergeScript = pkgs.writeScript "hermes-config-merge" ''
    #!${pkgs.python3.withPackages (ps: [ ps.pyyaml ])}/bin/python3
    import json, yaml, sys
    from pathlib import Path

    nix_json, config_path = sys.argv[1], Path(sys.argv[2])

    with open(nix_json) as f:
        nix = json.load(f)

    existing = {}
    if config_path.exists():
        with open(config_path) as f:
            existing = yaml.safe_load(f) or {}

    def deep_merge(base, override):
        result = dict(base)
        for k, v in override.items():
            if k in result and isinstance(result[k], dict) and isinstance(v, dict):
                result[k] = deep_merge(result[k], v)
            else:
                result[k] = v
        return result

    merged = deep_merge(existing, nix)
    with open(config_path, "w") as f:
        yaml.dump(merged, f, default_flow_style=False, sort_keys=False)
  '';
in
{
  options.modules.dev.hermes = with types; {
    enable = mkBoolOpt false;

    # Freeform settings deep-merged into ~/.hermes/config.yaml on activation.
    # Nix-declared keys always win; keys added by Hermes at runtime (skills,
    # cron, model changes via `hermes model`) are preserved across rebuilds.
    settings = mkOpt attrs {
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };

    # Structured MCP server definitions. Merged into settings.mcp_servers.
    # Servers added interactively via `hermes mcp add` are preserved — the
    # deep-merge only overwrites keys that Nix declares.
    mcpServers = mkOpt (attrsOf (submodule {
      options = {
        # Stdio transport
        command = mkOpt (nullOr str) null;
        args = mkOpt (listOf str) [ ];
        env = mkOpt (attrsOf str) { };

        # HTTP transport
        url = mkOpt (nullOr str) null;
        headers = mkOpt (attrsOf str) { };

        # Authentication
        auth = mkOpt (nullOr (enum [ "oauth" ])) null;

        # Enable/disable
        enabled = mkOpt bool true;

        # Timeouts
        timeout = mkOpt (nullOr int) null;

        # Tool filtering
        tools = mkOpt (nullOr (submodule {
          options = {
            include = mkOpt (listOf str) [ ];
            exclude = mkOpt (listOf str) [ ];
          };
        })) null;
      };
    })) { };

    # Workspace documents installed into ~/.hermes/ on activation.
    # Keys are filenames (e.g. "SOUL.md"), values are inline strings or paths.
    # These are copied (not symlinked) so Hermes can modify them at runtime.
    documents = mkOpt (attrsOf (either str path)) { };

    # Additional packages available alongside hermes.
    extraPackages = mkOpt (listOf package) [ ];
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = [ hermesPkg ] ++ cfg.extraPackages;

        activation.hermesSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # Create directory structure
          mkdir -p "${hermesHome}"/{cron,sessions,logs,memories,skills,hooks,mcp-tokens}

          # Deep-merge Nix settings into config.yaml
          ${configMergeScript} ${settingsJson} "${hermesHome}/config.yaml"

          # Install documents (copy, not symlink — Hermes may modify at runtime)
          ${concatStringsSep "\n" (
            mapAttrsToList (
              name: value:
              let
                src =
                  if builtins.isPath value || lib.isStorePath value then
                    value
                  else
                    pkgs.writeText "hermes-doc-${name}" value;
              in
              ''cp -f "${src}" "${hermesHome}/${name}"''
            ) cfg.documents
          )}
        '';
      };

      programs.fish.shellAliases = {
        hmc = "hermes chat";
      };
    };
  };
}
