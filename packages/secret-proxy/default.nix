{
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "secret-proxy";
  version = "0.1.0";

  src = ./.;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/secret-proxy $out/share/secret-proxy

    # Core proxy script
    cp secret_proxy.py $out/lib/secret-proxy/

    # CA certificate (public cert, safe to distribute)
    cp mitmproxy-ca-cert.pem $out/share/secret-proxy/

    # Documentation and examples
    cp README.md $out/share/secret-proxy/
    cp secrets.env.example $out/share/secret-proxy/
    cp -r namespaces $out/share/secret-proxy/

    runHook postInstall
  '';

  meta = {
    description = "HTTP proxy that injects 1Password secrets into requests via mitmproxy";
    platforms = lib.platforms.all;
  };
}
