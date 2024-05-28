{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.helix;
in {
  options.modules.shell.helix = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    hm = {
      programs.helix = {
        enable = true;
        extraPackages = with pkgs; [
          helix-gpt
          nodePackages.bash-language-server
          nodePackages.vscode-css-languageserver-bin
          elixir-ls
          fsautocomplete
          terraform-ls
          nodePackages.typescript-language-server
          nodePackages.vscode-json-languageserver
          ocamlPackages.lsp
          yaml-language-server
        ];
        settings = {
          theme = "catppuccin_mocha";
          editor = {
            line-number = "relative";
            rulers = [ 80 ];
            "cursor-shape" = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            "indent-guides" = {
              render = true;
              character = "|";
            };
          };
        };
      };
    };
  };
}
