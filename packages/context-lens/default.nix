{
  lib,
  stdenv,
  fetchzip,
  nodejs,
  makeWrapper,
}:

# Context Lens ships pre-built with bundled dependencies in dist/.
# All runtime deps are pure JS (no native addons), so we assemble
# node_modules from npm tarballs directly.
let
  version = "0.6.1";

  deps = {
    contextio-core = fetchzip {
      url = "https://registry.npmjs.org/@contextio/core/-/core-0.2.1.tgz";
      hash = "sha256-Zp0yZqqdVoKHLYAQoJBeo2X7yFwdg76t+7Rr8XHx8Mc=";
    };
    contextio-proxy = fetchzip {
      url = "https://registry.npmjs.org/@contextio/proxy/-/proxy-0.2.2.tgz";
      hash = "sha256-N4T6ZirZ8+cYE3tZEHytmGqO5bIwX90oHFMh+bQlFwk=";
    };
    hono = fetchzip {
      url = "https://registry.npmjs.org/hono/-/hono-4.11.9.tgz";
      hash = "sha256-QwZi0Z97HzTZEU8gRX2DbT0j3R7+2FbAA2eO+t9k63c=";
    };
    hono-node-server = fetchzip {
      url = "https://registry.npmjs.org/@hono/node-server/-/node-server-1.19.9.tgz";
      hash = "sha256-Yza09vu4+Bur0VpZWGFy7N7N+o5Sq7l8U1mZyQJs7cU=";
    };
    js-tiktoken = fetchzip {
      url = "https://registry.npmjs.org/js-tiktoken/-/js-tiktoken-1.0.21.tgz";
      hash = "sha256-ZFCkl7LI6QZgGB51qoDnYneoYbtpzxyUvrFE1hACLX8=";
    };
    valibot = fetchzip {
      url = "https://registry.npmjs.org/valibot/-/valibot-1.2.0.tgz";
      hash = "sha256-jZ/aqfdPsOtx0GyAw4LJJUpxj87LCyrHj0BMiRC6rwM=";
    };
    base64-js = fetchzip {
      url = "https://registry.npmjs.org/base64-js/-/base64-js-1.5.1.tgz";
      hash = "sha256-LZGj7J4BbIJL9l6ECGOwv/mtGWvPNoNs9F+RrJUH9Ds=";
    };
  };
in
stdenv.mkDerivation {
  pname = "context-lens";
  inherit version;

  src = fetchzip {
    url = "https://registry.npmjs.org/context-lens/-/context-lens-${version}.tgz";
    hash = "sha256-TZ/Z2L3S2Ec5tEjclBwUdWavTY3WrPn5krffPGhvUSE=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    pkg=$out/lib/context-lens
    mkdir -p $pkg/node_modules/@contextio $pkg/node_modules/@hono $out/bin

    cp -r . $pkg

    # Assemble node_modules with runtime deps.
    # Packages that need nested node_modules are copied (not symlinked)
    # and made writable so we can create subdirectories inside them.
    ln -s ${deps.contextio-core} $pkg/node_modules/@contextio/core
    cp -r ${deps.contextio-proxy} $pkg/node_modules/@contextio/proxy
    chmod -R u+w $pkg/node_modules/@contextio/proxy
    ln -s ${deps.hono} $pkg/node_modules/hono
    cp -r ${deps.hono-node-server} $pkg/node_modules/@hono/node-server
    chmod -R u+w $pkg/node_modules/@hono/node-server
    cp -r ${deps.js-tiktoken} $pkg/node_modules/js-tiktoken
    chmod -R u+w $pkg/node_modules/js-tiktoken
    ln -s ${deps.valibot} $pkg/node_modules/valibot
    ln -s ${deps.base64-js} $pkg/node_modules/base64-js

    # @contextio/proxy depends on @contextio/core
    mkdir -p $pkg/node_modules/@contextio/proxy/node_modules/@contextio
    ln -s ${deps.contextio-core} $pkg/node_modules/@contextio/proxy/node_modules/@contextio/core

    # @hono/node-server peer-depends on hono
    mkdir -p $pkg/node_modules/@hono/node-server/node_modules
    ln -s ${deps.hono} $pkg/node_modules/@hono/node-server/node_modules/hono

    # js-tiktoken depends on base64-js
    mkdir -p $pkg/node_modules/js-tiktoken/node_modules
    ln -s ${deps.base64-js} $pkg/node_modules/js-tiktoken/node_modules/base64-js

    # CLI wrapper
    makeWrapper ${nodejs}/bin/node $out/bin/context-lens \
      --add-flags "$pkg/dist/cli.js"

    # Standalone server wrappers (for launchd services)
    makeWrapper ${nodejs}/bin/node $out/bin/context-lens-proxy \
      --add-flags "$pkg/dist/proxy/server.js"

    makeWrapper ${nodejs}/bin/node $out/bin/context-lens-analysis \
      --add-flags "$pkg/dist/analysis/server.js"

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "See what your AI sees — framework-agnostic LLM context window visualizer";
    homepage = "https://github.com/larsderidder/context-lens";
    license = lib.licenses.mit;
    mainProgram = "context-lens";
    platforms = lib.platforms.all;
  };
}
