{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.fish;
in
{
  config = mkIf cfg.enable {
    programs.fish.enable = true;

    home-manager.users."${config.user.name}" = {
      programs.fish = {
        shellAliases = {
          pbcopy = "xclip -selection clipboard";
          pbpaste = "xclip -selection clipboard -o";
        };
      };
    };

    environment = {
      pathsToLink = [ "/share/fish" ];
      shells = [ pkgs.fish ];
    };
  };
}
