{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-20.09-darwin";
    nixos-stable.url = "github:nixos/nixpkgs/nixos-20.09";

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
              nixpkgs-stable = if system == "x86_64-darwin" then
                nixpkgs-stable-darwin
              else
                nixos-stable;
            in {
              master = nixpkgs-master.legacyPackages.${system};
              stable = nixpkgs-stable.legacyPackages.${system};
            })
        ];
      };

      # Modules shared between nix-darwin and plain home-manager
      homeManagerCommonConfig = with self.homeManagerModules; {
        imports = [ ./home configs.starship.symbols ];
      };

      # Modules shared by nix-darwin configurations
      nixDarwinCommonModules = { user }: [
        ./darwin
        home-manager.darwinModules.home-manager
        {
          nixpkgs = nixpkgsConfig;
          # Hack to support legacy workflows that use <nixpkgs>
          nix.nixPath = { nixpkgs = "$HOME/.config/nixpkgs/nixpkgs.nix"; };
          users.users.${user}.home = "/Users/${user}";
          home-manager.useGlobalPkgs = true;
          home-manager.users.${user} = homeManagerCommonConfig;
        }
      ];

    in {
      darwinConfigurations = {
        # Minimal configuration to bootstrap systems
        bootstrap = darwin.lib.darwinSystem {
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsConfig; } ];
        };

        # My personal machine
        personalMacbookPro = darwin.lib.darwinSystem {
          modules = nixDarwinCommonModules { user = "bromanko"; } ++ [{
            networking.computerName = "bromanko Macbook Pro";
            networking.hostName = "bromanko-macbook-pro";

            environment.variables.PROJECTS = "$HOME/Code";
          }];
        };

        # Main work machine
        workMacbookPro = darwin.lib.darwinSystem {
          modules = nixDarwinCommonModules { user = "bromanko"; } ++ [ { } ];
        };
      };

      # Work dev server
      workDevServer = home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/bromanko";
        username = "bromanko";
        configuration = {
          imports = [ homeManagerCommonConfig ];
          nixpkgs = nixpkgsConfig;
        };
      };

      overlays = map import ((import ./lsnix.nix) ./overlays);

      homeManagerModules = {
        configs.starship.symbols = import ./home/configs/starship-symbols.nix;
      };

      # Add re-export nixpkgs packages with overlays.
      # This is handy in combination with `nix-registry add my /Users/bromanko/.config/nixpkgs`
    } // flake-utils.lib.eachDefaultSystem (system: {
      legacyPackages = import nixpkgs {
        inherit system;
        inherit (nixpkgsConfig) config overlays;
      };
    });
}
