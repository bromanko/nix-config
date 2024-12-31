{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.my;
{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ../modules/users.nix
      ../modules/fonts.nix
      ../modules/home-manager.nix
      ../modules/homebrew.nix
      ../modules/homeage.nix
    ]
    # Must toString the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../modules/home-manager) import)
    ++ (mapModulesRec' (toString ../modules/linux) import);

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true'';
  };

  users.users.${config.user.name} = mkAliasDefinitions config.user;

  hm = {
    home = {
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

  environment.systemPackages = with pkgs; [
    xorg.xdpyinfo
    killall
    git
  ];
}
