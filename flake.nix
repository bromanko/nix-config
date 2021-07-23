{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-21.05-darwin";

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
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixpkgs-darwin, darwin
    , home-manager, flake-utils, ... }:
    let
      inherit (lib.my) mapModules mapDarwinHosts mapNixosHosts;

      mkPkgs = system: pkgs: extraOverlays:
        import pkgs {
          system = system;
          config.allowUnfree = true;
          overlays = extraOverlays ++ (lib.attrValues self.overlays);
        };
      pkgs = mkPkgs "x86_64-linux" nixpkgs [ self.overlay ];
      pkgsDarwin = mkPkgs "x86_64-darwin" nixpkgs-darwin [ self.overlay ];
      pkgs' = mkPkgs "x86_64-linux" nixpkgs-unstable [ ];

      lib = nixpkgs.lib.extend (self: super: {
        my = import ./lib {
          inherit pkgs inputs;
          lib = self;
        };
      });

    in {
      # For repl debugging
      passtru = { inherit lib inputs; };

      overlay = final: prev: { unstable = pkgs'; };

      overlays = mapModules ./overlays import;

      nixosConfigurations = mapNixosHosts ./hosts/nixos;
      darwinConfigurations = mapDarwinHosts ./hosts/darwin;

      # Work dev server
      # workDevServer = home-manager.lib.homeManagerConfiguration {
      #   system = "x86_64-linux";
      #   homeDirectory = "/home/bromanko";
      #   username = "bromanko";
      #   configuration = {
      #     imports = [ homeManagerCommonConfig ];
      #     nixpkgs = nixpkgsConfig;
      #   };
      # };

      # homeManagerModules = {
      #   configs.starship.symbols = import ./home/configs/starship-symbols.nix;
      # };

    };
}
