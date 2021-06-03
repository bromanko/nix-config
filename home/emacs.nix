{ config, pkgs, lib, ... }:

{
  programs.doom-emacs =
    {
      enable = true;
      doomPrivateDir = ./programs/emacs/doom.d;
      emacsPackage = if pkgs.stdenv.isDarwin then pkgs.emacsMacport else pkgs.emacs;
      emacsPackagesOverlay = self: super: {
        lsp-mode = super.lsp-mode.overrideattrs (esuper: {
          buildinputs = esuper.buildinputs ++ [ pkgs.elixir_ls ];
        });
        magit-delta = super.magit-delta.overrideattrs (esuper: {
          buildinputs = esuper.buildinputs ++ [ pkgs.git ];
        });
      };
    };
}
