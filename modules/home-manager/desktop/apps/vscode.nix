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
          # Looks
          catppuccin.catppuccin-vsc
          catppuccin.catppuccin-vsc-icons

          # # Feel
          bodil.file-browser
          vscodevim.vim
          vspacecode.vspacecode
          vspacecode.whichkey
          usernamehw.errorlens

          # General
          mkhl.direnv
          kahole.magit
          bradlc.vscode-tailwindcss

          # TOML
          tamasfe.even-better-toml

          # nix
          jnoortheen.nix-ide

          # AI
          github.copilot
          github.copilot-chat
          # continue.continue # Not supported on Darwin

          # Rust
          serayuzgur.crates
          rust-lang.rust-analyzer

          # Elixir
          elixir-lsp.vscode-elixir-ls
          phoenixframework.phoenix
        ];
      };
      home = {
        activation = {
          vscodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
