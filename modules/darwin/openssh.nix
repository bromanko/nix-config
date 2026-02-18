{ lib, config, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.openssh;
in
{
  options.modules.openssh = with types; {
    enable = mkBoolOpt false;

    tailscaleOnly = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.openssh.enable = true;

    users.users.${config.user.name}.openssh.authorizedKeys.keys = config.authorizedKeys;

    environment.etc."ssh/sshd_config.d/200-disable-password-auth.conf".text = ''
      PasswordAuthentication no
      PermitRootLogin no
      KbdInteractiveAuthentication no
      PermitEmptyPasswords no
      ChallengeResponseAuthentication no
    '';

    # On macOS, launchd manages the SSH socket and ignores ListenAddress in
    # sshd_config. Use pf (packet filter) to restrict SSH to Tailscale only.
    # Rules are loaded under the com.apple anchor so they're evaluated by the
    # existing main ruleset (which has `anchor "com.apple/*"`).
    environment.etc."pf.anchors/com.apple.nix-darwin.openssh" = mkIf cfg.tailscaleOnly {
      text = ''
        # Allow SSH from Tailscale CGNAT range only
        pass in quick on lo0 proto tcp from any to any port 22
        pass in quick proto tcp from 100.64.0.0/10 to any port 22
        block in quick proto tcp from any to any port 22
      '';
    };

    launchd.daemons.pf-openssh = mkIf cfg.tailscaleOnly {
      serviceConfig = {
        Label = "org.nix-darwin.pf-openssh";
        ProgramArguments = [
          "/sbin/pfctl"
          "-a"
          "com.apple/nix-darwin.openssh"
          "-f"
          "/etc/pf.anchors/com.apple.nix-darwin.openssh"
        ];
        RunAtLoad = true;
      };
    };
  };
}
