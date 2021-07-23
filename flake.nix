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

      # TODO redo this to create the config and pass that to mapHosts
      mkPkgs = pkgs: extraOverlays:
        import pkgs {
          config.allowUnfree = true;
          overlays = extraOverlays ++ (lib.attrValues self.overlays);
        };
      pkgs = mkPkgs nixpkgs [ self.overlay ];
      pkgs' = mkPkgs nixpkgs-unstable [ ];

      lib = nixpkgs.lib.extend (self: super: {
        my = import ./lib {
          inherit pkgs inputs;
          lib = self;
        };
      });

    in {
      # For repl debugging
      passthru = { inherit lib inputs pkgs; };

      overlay = final: prev: { unstable = pkgs'; };
      overlays = mapModules ./overlays import;

      nixosConfigurations = mapNixosHosts ./hosts/nixos;
      darwinConfigurations =
        mapDarwinHosts ./hosts/darwin (lib.attrValues self.overlays);
    };
}
