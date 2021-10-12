{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.commonPkgs;
in {
  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        bottom
        curl
        delta
        duf
        du-dust
        gnupg
        httpie
        jq
        python3
        ripgrep
        shellcheck
        shfmt
        tldr
        tmux
        tree
        yq
      ];
    };
  };
}
