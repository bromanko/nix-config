{
  autoPatchelfHook,
  fetchzip,
  installShellFiles,
  lib,
  stdenv,
}:

let
  inherit (stdenv.hostPlatform) system;
  version = "2.38.0-beta.01";

  fetch =
    platform: hash:
    fetchzip {
      url = "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_${platform}_v${version}.zip";
      inherit hash;
      stripRoot = false;
    };

  sources = {
    aarch64-darwin = fetch "darwin_arm64" "sha256-xqeQIn2NlRkUkUzDiCCW64Lf2mnZTgp/22R/dCStV/8=";
    aarch64-linux = fetch "linux_arm64" "sha256-gRG1hQKkv/+8sC2nNbhYn7BYnzuc3rU1yOLMVQu+z90=";
    x86_64-linux = fetch "linux_amd64" "sha256-xRmqPvl961zDnwFAVaSGUpU3ex7L3j+CtBLK8/Vys7E=";
  };
  platforms = builtins.attrNames sources;
in
stdenv.mkDerivation {
  pname = "1password-cli-beta";
  inherit version;

  src =
    if builtins.elem system platforms then
      sources.${system}
    else
      throw "1Password CLI beta is not available for ${system}";

  nativeBuildInputs = [
    installShellFiles
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  installPhase = ''
    runHook preInstall

    install -D op $out/bin/op

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    HOME=$TMPDIR
    installShellCompletion --cmd op \
      --bash <($out/bin/op completion bash) \
      --fish <($out/bin/op completion fish) \
      --zsh <($out/bin/op completion zsh)
  '';

  dontStrip = stdenv.hostPlatform.isDarwin;

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck

    test "$($out/bin/op --version)" = "${version}"
    $out/bin/op environment read --help | grep -F \
      "Read environment variables from a 1Password Environment."

    runHook postInstallCheck
  '';

  meta = {
    description = "Beta 1Password CLI with Environment support";
    homepage = "https://developer.1password.com/docs/cli/";
    downloadPage = "https://releases.1password.com/developers/cli-beta/";
    license = lib.licenses.unfree;
    mainProgram = "op";
    inherit platforms;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
