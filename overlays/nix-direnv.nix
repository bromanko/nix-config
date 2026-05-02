final: prev: {
  nix-direnv = prev.nix-direnv.overrideAttrs (old: {
    # nix-direnv's derivation copies $src directly and does not run install
    # hooks by default. Add the hooks so we can patch the installed direnvrc
    # before resholve rewrites command paths during fixup.
    installPhase = ''
      runHook preInstall
      cp -R "$src" "$out"
      runHook postInstall
    '';

    postInstall = (old.postInstall or "") + ''
      chmod u+w "$out/share/nix-direnv" "$out/share/nix-direnv/direnvrc"
      patch -p1 -d "$out" < ${./patches/nix-direnv-bash-5.3-reload.patch}
    '';
  });
}
