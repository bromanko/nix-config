self: super: rec {
  kitty = super.kitty.overrideAttrs (old: rec {
    # TODO This should only be set for aarch64
    preBuild =
      old.lib.optional old.stdenv.isDarwin "MACOSX_DEPLOYMENT_TARGET=10.16";
  });
}
