{ lib, config, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.openssh;
in
{
  options.modules.openssh = with types; {
    enable = mkBoolOpt false;
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
  };
}
