{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.vscode;
in
{
  options.modules.desktop.apps.vscode = {
    enable = mkBoolOpt false;
  };

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
          fill-labs.dependi
          rust-lang.rust-analyzer

          # Elixir
          elixir-lsp.vscode-elixir-ls
          phoenixframework.phoenix
        ];
      };
      home = {
        file = {
          "Library/Application Support/Code/User/settings.json".source =
            config.hm.lib.file.mkNixConfigSymlink ../../../../configs/vscode/settings.json;
          "Library/Application Support/Code/User/keybindings.json".source =
            config.hm.lib.file.mkNixConfigSymlink ../../../../configs/vscode/keybindings.json;
        };
      };
    };
  };
}
