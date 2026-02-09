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

    exec limactl shell "''${flags[@]}" lima-dev "''${cmd[@]}"
  '';
  meta = with lib; {
    description = "Shell into the Lima dev VM";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "limassh";
  };
}
