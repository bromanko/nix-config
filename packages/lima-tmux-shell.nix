{ pkgs, lib, ... }:

pkgs.writeShellApplication {
  name = "limassh";
  runtimeInputs = with pkgs; [ openssh ];
  text = let q = "'"; in ''
    # Connect to a Lima VM with tmux socket forwarding
    #
    # Forwards the host tmux Unix socket into the VM so that Claude Code's
    # tmux-titles plugin can set window names from inside the guest.
    #
    # Usage: limassh [instance-name] [-- extra-args...]
    #   instance-name  Lima instance (default: "lima-dev")
    #   extra-args     Additional arguments passed to the shell session

    # --- Parse arguments ---
    instance="lima-dev"
    extra_args=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --)
          shift
          extra_args=("$@")
          break
          ;;
        -*)
          echo "Unknown option: $1" >&2
          echo "Usage: limassh [instance-name] [-- extra-args...]" >&2
          exit 1
          ;;
        *)
          instance="$1"
          shift
          ;;
      esac
    done

    # --- Validate tmux environment ---
    if [[ -z "''${TMUX:-}" ]]; then
      echo "Error: not running inside tmux (\$TMUX is not set)" >&2
      exit 1
    fi

    if [[ -z "''${TMUX_PANE:-}" ]]; then
      echo "Error: \$TMUX_PANE is not set" >&2
      exit 1
    fi

    # --- Extract host tmux socket path ---
    # $TMUX format: /path/to/socket,pid,session
    host_socket="''${TMUX%%,*}"

    if [[ ! -S "$host_socket" ]]; then
      echo "Error: tmux socket not found at $host_socket" >&2
      exit 1
    fi

    # --- Forwarded socket path inside the VM ---
    vm_socket_dir="/tmp/tmux-forwarded"
    vm_socket="''${vm_socket_dir}/default"

    # --- Locate SSH config file ---
    ssh_config_file="$HOME/.lima/''${instance}/ssh.config"

    if [[ ! -f "$ssh_config_file" ]]; then
      echo "Error: SSH config not found at $ssh_config_file" >&2
      echo "Is the instance running? Try: limactl list" >&2
      exit 1
    fi

    # The SSH host alias is "lima-<instance>"
    ssh_host="lima-''${instance}"

    # --- Ensure the socket directory exists inside the VM ---
    ssh -F "$ssh_config_file" "$ssh_host" "mkdir -p $vm_socket_dir" 2>/dev/null

    # --- Connect with socket forwarding ---
    exec ssh -F "$ssh_config_file" \
      -R "''${vm_socket}:''${host_socket}" \
      -o StreamLocalBindUnlink=yes \
      -t \
      "$ssh_host" \
      "export TMUX=${q}''${vm_socket},0,0${q}; export TMUX_PANE=${q}''${TMUX_PANE}${q}; exec \$SHELL -l ''${extra_args[*]:+''${extra_args[*]}}"
  '';
  meta = with lib; {
    description = "Connect to a Lima VM with tmux socket forwarding";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "limassh";
  };
}
