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
          bbenoist.nix
          rust-lang.rust-analyzer
          vscodevim.vim
          vspacecode.vspacecode
          vspacecode.whichkey
        ];
      };
    };
  };
}
