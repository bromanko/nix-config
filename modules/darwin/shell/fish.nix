{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;

let
  cfg = config.modules.shell.fish;
  nixConfigDir = "$HOME/Code/nix-config";
  nixConfigRepo = "github:bromanko/nix-config";
in
{
  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
    };

    environment = {
      shells = [ pkgs.fish ];
      pathsToLink = [ "/share/fish" ];
    };

    hm.programs.fish.functions = {
      "rebuild!" = ''
        set -l host (hostname -s)
        if test -d ${nixConfigDir}
          echo "Rebuilding from local config..."
          sudo darwin-rebuild switch --flake ${nixConfigDir}#$host
        else
          echo "Local config not found, building from remote..."
          set -l tmpdir (mktemp -d)
          nix build ${nixConfigRepo}#darwinConfigurations.$host.system -o $tmpdir/result
          and sudo $tmpdir/result/sw/bin/darwin-rebuild switch --flake ${nixConfigRepo}#$host
          rm -rf $tmpdir
        end
      '';
    };
  };
}
