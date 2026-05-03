{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.secretEnv;

  invalidVariables = filter (
    name: builtins.match "[A-Za-z_][A-Za-z0-9_]*" name == null
  ) cfg.variables;
  hasDuplicateVariables = length (unique cfg.variables) != length cfg.variables;

  python = pkgs.python3.withPackages (ps: [ ps.python-dotenv ]);

  loader = pkgs.writeShellScript "secret-env-loader" ''
    exec ${python}/bin/python - "$@" <<'PY'
    import os
    import sys

    from dotenv import dotenv_values


    def main() -> int:
        if len(sys.argv) < 2:
            print("usage: secret-env-loader ENV_FILE [VARIABLE ...]", file=sys.stderr)
            return 2

        env_file = os.path.expandvars(os.path.expanduser(sys.argv[1]))
        variable_names = sys.argv[2:]

        values = dotenv_values(env_file, interpolate=False)
        out = sys.stdout.buffer

        for name in variable_names:
            if name not in values or values[name] is None:
                continue

            out.write(name.encode("utf-8"))
            out.write(b"\0")
            out.write(values[name].encode("utf-8"))
            out.write(b"\0")

        return 0


    if __name__ == "__main__":
        raise SystemExit(main())
    PY
  '';
in
{
  options.modules.shell.secretEnv = with types; {
    enable = mkBoolOpt false;

    envFile = mkOpt' str "$HOME/.config/secret-proxy/secrets.env" ''
      Dotenv file to load secrets from when starting an interactive fish shell.
      The value may contain shell-expanded variables such as $HOME.
    '';

    variables = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "GITHUB_TOKEN"
        "GEMINI_API_KEY"
      ];
      description = ''
        Explicit allow-list of variables to export from envFile. Variables not
        listed here are parsed but never exported into the fish session.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.shell.fish.enable;
        message = "modules.shell.secretEnv requires modules.shell.fish.enable.";
      }
      {
        assertion = cfg.variables != [ ];
        message = "modules.shell.secretEnv.variables must list at least one variable.";
      }
      {
        assertion = invalidVariables == [ ];
        message = "modules.shell.secretEnv.variables contains invalid environment variable names: ${concatStringsSep ", " invalidVariables}";
      }
      {
        assertion = !hasDuplicateVariables;
        message = "modules.shell.secretEnv.variables must not contain duplicate names.";
      }
    ];

    hm.programs.fish.interactiveShellInit = mkAfter ''
      set -l secret_env_file "${cfg.envFile}"
      set -l secret_env_variables ${escapeShellArgs cfg.variables}

      if test -r "$secret_env_file"
          for name in $secret_env_variables
              set -e $name
          end

          ${loader} "$secret_env_file" $secret_env_variables | while read -lz name; and read -lz value
              set -gx $name $value
          end
      end
    '';
  };
}
