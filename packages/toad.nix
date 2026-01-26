{
  python314,
  fetchPypi,
  lib,
  makeWrapper,
  claude-code-acp,
}:

python314.pkgs.buildPythonApplication rec {
  pname = "batrachian-toad";
  version = "0.5.35";
  pyproject = true;

  src = fetchPypi {
    pname = "batrachian_toad";
    inherit version;
    hash = "sha256-cWqbJyTnXuyxLjHSJcDBSGJ/CPRxWJixWeBKY42X1nQ=";
  };

  nativeBuildInputs = [ makeWrapper ];

  build-system = with python314.pkgs; [
    hatchling
  ];

  dependencies = with python314.pkgs; [
    textual
    click
    gitpython
    tree-sitter
    httpx
    platformdirs
    rich
    typeguard
    xdg-base-dirs
    textual-serve
    textual-speedups
    packaging
    bashlex
    pathspec
    google-re2
    notify-py
    pyperclip
    watchdog
    setproctitle
    psutil
  ];

  pythonImportsCheck = [ "toad" ];

  # nixpkgs versions are slightly behind PyPI requirements
  dontCheckRuntimeDeps = true;

  postFixup = ''
    wrapProgram $out/bin/toad \
      --prefix PATH : ${lib.makeBinPath [ claude-code-acp ]}
  '';

  meta = {
    description = "A unified interface for AI in your terminal";
    homepage = "https://github.com/batrachianai/toad";
    license = lib.licenses.mit;
    mainProgram = "toad";
  };
}
