{ pkgs }:
let
  linear = pkgs.callPackage ./linear-cli.nix { };
  caBundle = pkgs.runCommand "scherzo-proxy-ca-bundle" { } ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
      ${./secret-proxy/mitmproxy-ca-cert.pem} > "$out"
  '';
  proxyEnvironment = ''
    export HTTP_PROXY=http://127.0.0.1:17329
    export HTTPS_PROXY="$HTTP_PROXY"
    export http_proxy="$HTTP_PROXY" https_proxy="$HTTPS_PROXY"
    export NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1
    export SSL_CERT_FILE=${caBundle} DENO_CERT=${caBundle}
  '';
  client =
    name: binary: credential:
    pkgs.writeShellScriptBin name ''
      ${proxyEnvironment}
      ${credential}
      exec ${binary} "$@"
    '';
in
pkgs.symlinkJoin {
  name = "scherzo-proxy-tools";
  passthru = { inherit caBundle; };
  paths = [
    (client "gh" "${pkgs.gh}/bin/gh" ''
      # Operator-approved reuse of the existing host token for reads and PRs.
      export GH_TOKEN='{{scherzo:GITHUB_TOKEN}}'
    '')
    (client "linear" "${linear}/bin/linear" ''
      export LINEAR_API_KEY='{{scherzo:LINEAR_API_KEY}}'
    '')
    (pkgs.writeShellScriptBin "git" ''
      # run_publication_git supplies this placeholder and its own askpass helper.
      # Git encodes Basic auth normally; the host proxy resolves the placeholder
      # inside it. Source checkout without this environment stays direct.
      if [ "''${GH_TOKEN:-}" = '{{scherzo:GITHUB_TOKEN}}' ]; then
        exec ${pkgs.git}/bin/git \
          -c http.https://github.com/scherzo-systems/scherzo-cloud.git.proxy=http://127.0.0.1:17329 \
          -c http.https://github.com/scherzo-systems/scherzo-cloud.git.sslCAInfo=${caBundle} \
          "$@"
      fi
      exec ${pkgs.git}/bin/git "$@"
    '')
  ];
}
