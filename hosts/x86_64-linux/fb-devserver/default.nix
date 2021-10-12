{ config, lib, pkgs, ... }:

{
  modules = {
    shell = {
      commonPkgs.enable = true;
      zsh.enable = true;
      bat.enable = true;
      git.enable = true;
      starship.enable = true;
      fzf.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    dev = {
      nix.enable = true;
      nodejs.enable = true;
    };
    editor = {
      neovim.enable = true;
      emacs.enable = true;
    };
  };

  home = {
    sessionVariables = {
      CURL_NIX_FLAGS = "-x http://fwdproxy:8082 --proxy-insecure";
      HTTP_PROXY = "http://fwdproxy:8080";
      HTTPS_PROXY = "http://fwdproxy:8080";
    };
  };
}
