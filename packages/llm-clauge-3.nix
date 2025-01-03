{
  python3,
  fetchFromGitHub,
  lib,
}:

python3.pkgs.buildPythonPackage rec {
  pname = "llm-claude-3";
  version = "0.10";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-claude-3";
    rev = version;
    hash = "sha256-3WQufuWlntywgVQUJeQoA3xXtCOIgbG+t4vnKRU0xPA=";
  };

  nativeBuildInputs = with python3.pkgs; [
    setuptools
    wheel
  ];

  propagatedBuildInputs = with python3.pkgs; [
    anthropic
  ];

  passthru.optional-dependencies = with python3.pkgs; {
    test = [
      pytest
      pytest-recording
      pytest-asyncio
    ];
  };

  pythonImportsCheck = [ ];

  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "";
    homepage = "https://github.com/simonw/llm-claude-3";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "llm-claude-3";
  };
}
