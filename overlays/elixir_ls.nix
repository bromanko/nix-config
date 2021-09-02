self: super: rec {
  elixir_ls = super.elixir_ls.overrideAttrs (old: rec {
    pname = "elixir_ls";
    version = "0.8.0";

    src = super.fetchFromGitHub {
      owner = "elixir-lsp";
      repo = "elixir-ls";
      rev = "v${version}";
      sha256 = "sha256-pUvONMTYH8atF/p2Ep/K3bwJUDxTzCsxLPbpjP0tQpM=";
      fetchSubmodules = true;
    };

    mixFodDeps = super.beamPackages.fetchMixDeps {
      pname = "mix-deps-${pname}";
      inherit src version;
      sha256 = "sha256-YRzPASpg1K2kZUga5/aQf4Q33d8aHCwhw7KJxSY56k4=";
    };
  });
}
