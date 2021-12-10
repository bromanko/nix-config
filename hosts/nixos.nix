{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.my; {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../modules/users.nix
    ../modules/fonts.nix
    ../modules/home-manager.nix
  ]
  # Must toString the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../modules/home-manager) import)
    ++ (mapModulesRec' (toString ../modules/linux) import);

  nix = {
    package = pkgs.unstable.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true'';
  };

  users.users.${config.user.name} = mkAliasDefinitions config.user;

  environment.systemPackages = with pkgs; [ xorg.xdpyinfo killall git ];
}
