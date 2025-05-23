{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.aider-chat;
in
{
  options.modules.dev.aider-chat = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = with pkgs; [
          aider-chat
        ];

      };
    };

    modules.homeage = {
      file = {
        "aider.conf.yml" = {
          source = ../../../configs/aider/aider.conf.yml.age;
          symlinks = [ "$HOME/.aider.conf.yml" ];
        };
      };
    };
  };
}
