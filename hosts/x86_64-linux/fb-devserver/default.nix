{ config, lib, pkgs, ... }:

{
  modules.shell.zsh.enable = true;
  modules.desktop.apps.espanso.enable = true;

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
