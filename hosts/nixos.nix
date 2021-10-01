{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.my; {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ]
  # Must toString the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../modules/linux) import)
    ++ (mapModulesRec' (toString ../modules/home-manager) import)
    ++ (mapModulesRec' (toString ../modules/common) import);

  nix = {
    package = pkgs.nixFlakes;
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true'';
  };

  environment.systemPackages = with pkgs; [ xorg.xdpyinfo killall git ];

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "orig";

    # Workaround to enable installing via `nixos-install`
    # https://github.com/nix-community/home-manager/issues/1262
    sharedModules = [{ manual.manpages.enable = false; }];

    users."${config.user.name}".home = {

      # This value determines the Home Manager release that your configuration
      # is compatible with. This helps avoid breakage when a new Home Manager
      # release introduces backwards incompatible changes.
      #
      # You can update Home Manager without changing this value. See the Home
      # Manager release notes for a list of state version changes in each
      # release.
      stateVersion = "21.03";
    };
  };
}
