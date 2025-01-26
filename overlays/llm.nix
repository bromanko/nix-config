self: super: {
  llm =
    rec {
      pyWithPackages = (
        super.python3.withPackages (ps: [
          ps.llm
          super.my.llm-gemini
          super.my.llm-claude-3
        ])
      );
      llm = super.runCommandNoCCLocal "llm" { } ''
        mkdir -p $out/bin
        ln -s ${pyWithPackages}/bin/llm $out/bin/llm
      '';
    }
    .llm;
}
