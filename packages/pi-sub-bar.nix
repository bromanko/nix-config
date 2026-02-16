{
  lib,
  stdenv,
  fetchzip,
}:

# Pi extension package fetched from npm with deps assembled manually.
# pi-sub-bar has only 2 runtime deps (pi-sub-core, pi-sub-shared) with no
# further transitive dependencies, so we can wire up node_modules directly.
let
  version = "1.3.0";

  pi-sub-shared = fetchzip {
    url = "https://registry.npmjs.org/@marckrenn/pi-sub-shared/-/pi-sub-shared-${version}.tgz";
    hash = "sha256-Y6hGljD+0rWZ8xC005Tg188KBit+I8F+u0MZmAiNFOE=";
  };

  pi-sub-core = fetchzip {
    url = "https://registry.npmjs.org/@marckrenn/pi-sub-core/-/pi-sub-core-${version}.tgz";
    hash = "sha256-t8+036k/ZpbFZ5d0DlkYALzraBfY6GrHhfMtrpyTxBY=";
  };
in
stdenv.mkDerivation {
  pname = "pi-sub-bar";
  inherit version;

  src = fetchzip {
    url = "https://registry.npmjs.org/@marckrenn/pi-sub-bar/-/pi-sub-bar-${version}.tgz";
    hash = "sha256-gC0fNee/iwulstlZFiosxVUHOMMULkVb8PCEhONCSzw=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    pkg=$out/lib/pi-sub-bar
    mkdir -p $pkg/node_modules/@marckrenn

    cp -r . $pkg

    # Assemble node_modules with runtime deps.
    # pi-sub-core must be copied (not symlinked) because Node follows symlinks
    # when resolving modules. If symlinked, Node looks for pi-sub-shared
    # relative to the resolved nix store path instead of the local node_modules.
    cp -r ${pi-sub-core} $pkg/node_modules/@marckrenn/pi-sub-core
    chmod -R u+w $pkg/node_modules/@marckrenn/pi-sub-core
    ln -s ${pi-sub-shared} $pkg/node_modules/@marckrenn/pi-sub-shared

    # pi-sub-core also depends on pi-sub-shared; give it its own node_modules
    # so Node can resolve the dependency from pi-sub-core's directory.
    mkdir -p $pkg/node_modules/@marckrenn/pi-sub-core/node_modules/@marckrenn
    ln -s ${pi-sub-shared} $pkg/node_modules/@marckrenn/pi-sub-core/node_modules/@marckrenn/pi-sub-shared

    runHook postInstall
  '';

  meta = {
    description = "Usage widget extension for pi — shows current provider usage above the editor";
    homepage = "https://www.npmjs.com/package/@marckrenn/pi-sub-bar";
    license = lib.licenses.mit;
  };
}
