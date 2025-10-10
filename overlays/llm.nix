final: prev: {
  llm =
    rec {
      pyWithPackages = (
        prev.python3.withPackages (ps: [
          ps.llm
          prev.my.llm-gemini
          prev.my.llm-claude-3
        ])
      );
      llm = prev.runCommandNoCCLocal "llm" { } ''
        mkdir -p $out/bin
        ln -s ${pyWithPackages}/bin/llm $out/bin/llm
      '';
    }
    .llm;
}
