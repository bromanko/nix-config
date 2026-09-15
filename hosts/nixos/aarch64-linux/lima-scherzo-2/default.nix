{ lib, pkgs, ... }:
{
  imports = [ ../lima-scherzo ];
  networking.hostName = lib.mkForce "lima-scherzo-2";

  # Temporary catalog entry matching the operator's Home Manager setup.
  # No provider credentials are included; this VM needs its own OAuth login.
  systemd.services.scherzo-runner.preStart = lib.mkAfter ''
    install -d -m 0700 /var/lib/scherzo-cloud/.pi/agent
    install -m 0600 ${pkgs.writeText "scherzo-pi-models.json" (builtins.readFile ../../../../configs/lima/pi-models.json)} /var/lib/scherzo-cloud/.pi/agent/models.json
  '';
}
