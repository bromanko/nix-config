{
  python3,
  fetchFromGitHub,
  lib,
  ...
}:

python3.pkgs.buildPythonPackage rec {
  pname = "llm-gemini";
  version = "0.28.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-gemini";
    rev = version;
    hash = "sha256-lPap9EWVue7VdqDQ5io5Al53gzfChuylJChDUIMBDow=";
  };

  nativeBuildInputs = with python3.pkgs; [
    setuptools
    wheel
  ];

  propagatedBuildInputs = with python3.pkgs; [
    httpx
    ijson
  ];

  passthru.optional-dependencies = with python3.pkgs; {
    test = [
      pytest
    ];
  };

  pythonImportsCheck = [ ];

  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "LLM plugin to access Google's Gemini family of models";
    homepage = "https://github.com/simonw/llm-gemini";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
