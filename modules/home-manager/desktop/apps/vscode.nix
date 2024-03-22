{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.vscode;
in {
  options.modules.desktop.apps.vscode = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    hm = {
      programs.vscode = {
        enable = true;
        extensions = with pkgs.vscode-extensions; [
          catppuccin.catppuccin-vsc
          catppuccin.catppuccin-vsc-icons
          serayuzgur.crates
          mkhl.direnv
          kahole.magit
          tamasfe.even-better-toml
          bodil.file-browser
          github.copilot
          github.copilot-chat
          jnoortheen.nix-ide
          rust-lang.rust-analyzer
          vscodevim.vim
          vspacecode.vspacecode
          vspacecode.whichkey
          usernamehw.errorlens
        ];
      };
      home = {
        activation = {
          afterWriteBoundary = ''
            echo "Removing VSCode config files"
            rm -rf "$HOME/Library/Application Support/Code/User/"{settings,keybindings}.json

            echo "Writing VSCode config files"
            cp ${
              ../../../../configs/vscode/settings.json
            } "$HOME/Library/Application Support/Code/User/settings.json"
            cp ${
              ../../../../configs/vscode/keybindings.json
            } "$HOME/Library/Application Support/Code/User/keybindings.json"
          '';
        };
      };
    };
  };
}
