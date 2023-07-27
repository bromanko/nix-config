self: super: rec {
  llm = super.python3Packages.buildPythonApplication rec {
    pname = "llm";
    version = "0.4.1";

    src = super.fetchFromGitHub {
      owner = "simonw";
      repo = pname;
      rev = "refs/tags/${version}";
      hash = "sha256-Hd6OwougsXxJHn176+bUwc6ZFYE8tqFj/KJi8sjPnr4=";
    };

    postPatch = ''
      substituteInPlace setup.py \
        --replace "click-default-group-wheel" "click-default-group"
    '';

    propagatedBuildInputs = [
      super.python3Packages.click-default-group
      super.python3Packages.sqlite-utils
      super.python3Packages.openai
      super.python3Packages.pydantic
      super.python3Packages.pyyaml
      super.python3Packages.pluggy
    ];

    meta = with super.lib; {
      homepage = "https://github.com/simonw/llm";
      description = "Access large language models from the command-line";
      license = licenses.asl20;
      maintainers = with maintainers; [ bromanko ];
    };
  };
}
