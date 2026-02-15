{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.commonPkgs;
in
{
  options.modules.shell.commonPkgs = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = with pkgs; [
          ast-grep
          bottom
          curl
          delta
          difftastic
          duf
          dust
          gnupg
          httpie
          jq
          meld
          python3
          ripgrep
          shellcheck
          shfmt
          timg
          tldr
          tree
          yq
        ];
      };
    };
  };
}
