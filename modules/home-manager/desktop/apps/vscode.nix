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
            if [ ! -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
              echo "Writing VSCode settings.json"
              cp ${
                ../../../../configs/vscode/settings.json
              } "$HOME/Library/Application Support/Code/User/settings.json"
            else
              if ! cmp ${
                ../../../../configs/vscode/settings.json
              } "$HOME/Library/Application Support/Code/User/settings.json"; then
                echo "VSCode settings.json exists and is different"
                exit 1
              fi
            fi
            if [ ! -f "$HOME/Library/Application Support/Code/User/keybindings.json" ]; then
              echo "Writing VSCode keybindings.json"
              cp ${
                ../../../../configs/vscode/keybindings.json
              } "$HOME/Library/Application Support/Code/User/keybindings.json"
            else 
              if ! cmp ${
                ../../../../configs/vscode/keybindings.json
              } "$HOME/Library/Application Support/Code/User/keybindings.json"; then
                echo "VSCode keybindings.json exists and is different"
                exit 1
              fi
            fi
          '';
        };
      };
    };
  };
}
