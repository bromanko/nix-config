{ pkgs, lib, ... }:

pkgs.writeShellApplication {
  name = "limassh";
  runtimeInputs = with pkgs; [ lima ];
  text = ''
    # Wrapper around limactl shell that inserts "lima-dev" as the instance name.
    # Usage: limassh [flags...] [-- command...]
    #
    # Flags (e.g. --workdir) are passed before the instance name,
    # and any command after "--" is passed after it.
    #
    # When no command is provided, bootstrap into fish if available after the
    # NixOS config has been applied, but fall back to fish/bash/sh during early
    # provisioning so the shell still works before /run/current-system exists.

    flags=()
    cmd=()
    seen_dashdash=false

    for arg in "$@"; do
      if [[ "$seen_dashdash" == true ]]; then
        cmd+=("$arg")
      elif [[ "$arg" == "--" ]]; then
        seen_dashdash=true
      else
        flags+=("$arg")
      fi
    done

    if (( ''${#cmd[@]} > 0 )); then
      exec limactl shell "''${flags[@]}" lima-dev "''${cmd[@]}"
    else
      exec limactl shell "''${flags[@]}" lima-dev /bin/sh -lc '
        if [ -x /run/current-system/sw/bin/fish ]; then
          exec /run/current-system/sw/bin/fish -l
        elif command -v fish >/dev/null 2>&1; then
          exec fish -l
        elif command -v bash >/dev/null 2>&1; then
          exec bash -l
        else
          exec sh -l
        fi
      '
    fi
  '';
  meta = with lib; {
    description = "Shell into the Lima dev VM";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "limassh";
  };
}
