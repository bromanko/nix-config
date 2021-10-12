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
      NIX_CURL_FLAGS =
        "-p -x https://fwdproxy:8082 --proxy-cert /var/facebook/credentials/bromanko/x509/bromanko.pem";
      NIX_SSL_CERT_FILE =
        "/var/facebook/credentials/bromanko/x509/bromanko.pem";
      HTTP_PROXY = "http://fwdproxy:8080";
      HTTPS_PROXY = "http://fwdproxy:8080";
    };
  };
}
