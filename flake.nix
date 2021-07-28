{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # System management
    darwin.url = "github:hardselius/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Other sources
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, ... }:
    let
      inherit (lib.my) mapModules;

      mkPkgs = pkgs: extraOverlays:
        import pkgs {
          config.allowUnfree = true;
          overlays = extraOverlays ++ (lib.attrValues self.overlays);
        };

      pkgs = mkPkgs nixpkgs [ self.overlay ];

      lib = nixpkgs.lib.extend (self: super: {
        my = import ./lib {
          inherit pkgs inputs;
          lib = self;
        };
      });
    in {
      # For debugging
      passthru = {
        inherit pkgs lib;
        packages = self.packages;
      };

      lib = lib.my;

      overlay = final: prev: { my = self.packages; };

      overlays = mapModules ./overlays import;

      packages = mapModules ./packages (p: pkgs.callPackage p { });

      darwinConfigurations = {
        personal-mbp = darwin.lib.darwinSystem {
          modules = [
            { nixpkgs.config = { packageOverrides = pkgs: import pkgs; }; }
            (import ./modules/darwin)
            home-manager.darwinModule
            {

            }
          ];
        };
      };
    };
}
