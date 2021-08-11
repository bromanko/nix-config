{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.commonPkgs;
in {
  options.modules.shell.commonPkgs = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    users."${config.user.name}".home = {
      packages = with pkgs; [
        bottom
        curl
        delta
        duf
        du-dust
        gnupg
        httpie
        jq
        openssh
        peco
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
