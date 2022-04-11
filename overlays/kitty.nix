self: super: rec {
  kitty = super.kitty.overrideAttrs (old: rec {
    preBuild =
      super.lib.optional (super.stdenv.isDarwin && super.stdenv.isAarch64)
      "MACOSX_DEPLOYMENT_TARGET=10.16";
  });
}
