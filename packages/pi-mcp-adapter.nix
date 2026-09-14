{
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  python3,
}:

let
  version = "2.33.0";
  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "v${version}";
    hash = "sha256-6p0uDmtGse+vIH0yiYKBSpQQG0eiWcj9Q+uDcRs/Ulg=";
  };

  # Normalize an abbreviated package URL and fill integrity fields omitted
  # from nested development packages in the upstream lockfile. Nix parses the
  # complete lockfile even though the installation below omits dev packages.
  patchLockfile = ''
    python3 - <<'PY'
    import json
    from pathlib import Path

    path = Path("package-lock.json")
    lock = json.loads(path.read_text())
    packages = lock["packages"]

    packages["node_modules/@modelcontextprotocol/client"]["dependencies"][
        "@modelcontextprotocol/core"
    ] = "https://pkg.pr.new/@modelcontextprotocol/core@3b205e7dd2f997b6a87e479e36421f7eaa2058e0"

    integrities = {
        "pi-agent-core": "sha512-evyzXYWCLQGmcaBYHlmSku02r8qoN4SGI60GZABo6iV+H+nqX+P9ud8fEZ4GmRq9mUSREvvfX+w9dA9ThF9C6w==",
        "pi-ai": "sha512-wMsAdJMxuNri08vLqTyYVI201DQQezGhPSTkzYsHdw5dYX3rCNwEmSvpaAwhi7ELKI/2tE/CEgSWg/6iRxSgdQ==",
        "pi-client": "sha512-/V5hGHE4Zq+jG0GtwIB9PyBUOGd6gBLZ7lkQYFKchKnxYHeH3rmWC5xw4kpnZKKBuBuFTdLVbU9vEjlAGMMb2A==",
        "pi-protocol": "sha512-Ox1pciyeSPGEEUcxvR0/dJcrY7C6hrEGA8y71rOsvSIUlXN1Cbp/be/eoL71OGDBk5O97TeQPfWN6Ju/2Ehjww==",
        "pi-telemetry": "sha512-180/xGJtsq7IoR3p9EKWjRd0e9M4DkxInhlo9xyD7prDC7Qrhqq+nhvwrW0lFjPfXcEI2FSHmGCSyvSJE9GsaQ==",
        "pi-tui": "sha512-udeXFbgEhJ6JiB0uguwNVNkDy2FENfmtQwPcY+/iJ8GWeq18wkal1tKqa5YyeH0IqtX1vG0cGh8zfSYzyzVuLA==",
    }
    prefix = "node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/"
    for name, integrity in integrities.items():
        packages[prefix + name]["integrity"] = integrity

    path.write_text(json.dumps(lock, indent=2) + "\n")
    PY
  '';
in
buildNpmPackage {
  pname = "pi-mcp-adapter";
  inherit version src;

  npmDeps = fetchNpmDeps {
    inherit src;
    hash = "sha256-J6WrgVHAgsAXhCpvhJ8hZYhUEoqZ/xpiu1vW42y2mSA=";
    nativeBuildInputs = [ python3 ];
    postPatch = patchLockfile;
  };
  nativeBuildInputs = [ python3 ];
  postPatch = patchLockfile;

  npmInstallFlags = [ "--omit=dev" ];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    pkg=$out/lib/pi-mcp-adapter
    mkdir -p $pkg
    cp -r . $pkg

    runHook postInstall
  '';

  meta = {
    description = "MCP adapter extension for Pi";
    homepage = "https://github.com/nicobailon/pi-mcp-adapter";
    license = lib.licenses.mit;
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
