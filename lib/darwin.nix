{ inputs, lib, pkgs, ... }:

with lib;
with lib.my;
let sys = "x86_64-darwin";
in {
  mkHost = path:
    attrs@{ ... }:
    darwin.lib.darWinSystem {
      inherit system;
      specialArgs = { inherit lib inputs system; };
      modules = [
        { nixpkgs.pkgs = pkgs; }
        (filterAttrs (n: v: !elem n [ "system" ]) attrs)
        ../. # /default.nix
        (import path)
      ];
    };

  mapHosts = dir: attrs: mapModules dir (hostPath: mkHost hostPath attrs);
}

# darwinConfigurations = {
#   # My personal machine
#   personalMacbookPro = darwin.lib.darwinSystem {
#     modules =       #   };

#   # Main work machine
#   workMacbookPro = darwin.lib.darwinSystem {
#     modules = nixDarwinCommonModules { user = "bromanko"; } ++ [{
#       environment.systemPath = [ "$HOME/homebrew/bin/" ];
#       environment.variables.PROJECTS = "$HOME/Code";
#     }];
#   };
# };
