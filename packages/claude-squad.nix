{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "claude-squad";
  version = "1.0.14";

  src = fetchFromGitHub {
    owner = "smtg-ai";
    repo = "claude-squad";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zh4vhZMtKbNT3MxNr18Q/3XC0AecFf5tOYIRT1aFk38=";
  };

  vendorHash = "sha256-BduH6Vu+p5iFe1N5svZRsb9QuFlhf7usBjMsOtRn2nQ=";

  ldflags = [
    "-s"
    "-w"
  ];

  # Tests require git in sandbox
  doCheck = false;

  meta = {
    description = "Manage multiple AI agents in your terminal";
    homepage = "https://github.com/smtg-ai/claude-squad";
    license = lib.licenses.agpl3Only;
    mainProgram = "claude-squad";
  };
})
