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

  outputs = inputs@{ self, nixpkgs, flake-utils, darwin, home-manager, ... }:
    let
      inherit (lib.my) mapModules;

      system = "x86_64-linux";

      mkPkgs = pkgs: extraOverlays:
        import pkgs {
          inherit system;
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
        inherit pkgs lib nixpkgs;
        packages = self.packages;
      };

      packages.${system} = mapModules ./packages (p: pkgs.callPackage p { });

      overlay = final: prev: { my = self.packages.${system}; };

      overlays = mapModules ./overlays import;

      darwinConfigurations = lib.my.mapDarwinHosts ./hosts/darwin;
    };
}
