{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-20.09-darwin";

    # System management
    darwin.url = "github:hardselius/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Other sources
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, darwin, home-manager, flake-utils, ... }@inputs:
    let
      nixpkgsConfig = with inputs; {
        config = { allowUnfree = true; };
        overlays = self.overlays ++ [
          (final: prev:
            let
              system = prev.stdenv.system;
              nixpkgs-stable = nixpkgs-stable-darwin;
            in {
              master = nixpkgs-master.legacyPackages.${system};
              stable = nixpkgs-stable.legacyPackages.${system};
            })
        ];
      };

      # Modules shared by nix-darwin configurations.
      nixDarwinCommonModules = { user }: [ ./darwin ];

    in {
      darwinConfigurations = {
        bootstrap = darwin.lib.darwinSystem {
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsConfig; } ];
        };

        PersonalMacbookPro = darwin.lib.darwinSystem {
          modules = nixDarwinCommonModules { user = "bromanko"; } ++ [{
            networking.computerName = "bromanko's Macbook Pro";
            networking.hostName = "bromanko-macbook-pro";
          }];
        };
      };

      overlays = with inputs; [ ]; # ++ [ ./overlays ];

      darwinModules = { };

      homeManagerModules = { };
    } // flake-utils.lib.eachDefaultSystem (system: {
      legacyPackages = import nixpkgs {
        inherit system;
        inherit (nixpkgsConfig) config overlays;
      };
    });
}
