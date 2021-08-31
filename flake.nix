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
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, ... }:
    let
      inherit (lib.my) mapModules mapModulesRec;

      supportedSystems = [ "x86_64-darwin" "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlay ] ++ (lib.attrValues self.overlays);
        });

      lib = nixpkgs.lib.extend (self: super: {
        my = import ./lib {
          inherit pkgs inputs home-manager;
          lib = self;
        };
        hm = home-manager.lib.hm;
      });
    in {
      # For debugging
      passthru = {
        inherit pkgs lib nixpkgs;
        packages = self.packages;
      };

      packages = forAllSystems
        (system: mapModules ./packages (p: pkgs.${system}.callPackage p { }));

      overlay = final: prev: { my = self.packages.${prev.system}; };

      overlays = {}; # mapModules ./overlays import;

      darwinConfigurations = lib.my.mapDarwinHosts ./hosts/darwin;

      nixosConfigurations = lib.my.mapNixosHosts ./hosts/nixos;
    };
}
