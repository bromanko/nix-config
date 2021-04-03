# My own custom packages
self: super: {
  zsh-vim-mode = super.stdenv.mkDerivation rec {
    pname = "zsh-vim-mode";
    version = "HEAD";

    src = super.fetchFromGitHub {
      owner = "softmoth";
      repo = "zsh-vim-mode";
      rev = "1f9953b";
      sha256 = "a+6EWMRY1c1HQpNtJf5InCzU7/RphZjimLdXIXbO6cQ=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      install -Dm0644 zsh-vim-mode.plugin.zsh $out/share/zsh/plugins/zsh-vim-mode/zsh-vim-mode.plugin.zsh
    '';

    meta = with super.lib; {
      description = "Friendly bindings for ZSH's vi mode";
      homepage = "https://github.com/softmoth/zsh-vim-mode";
      license = licenses.mit;
      maintainers = with maintainers; [ bromanko ];
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
}
