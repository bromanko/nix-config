{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-21.11";

    # System management
    darwin.url = "github:LnL7/nix-darwin/master";
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

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, darwin, home-manager
    , emacs-overlay, ... }:
    let
      inherit (lib.my) mapModules mapModulesRec;

      supportedSystems = [ "aarch64-darwin" "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.input-fonts.acceptLicense = true;
          overlays = [ self.overlay emacs-overlay.overlay ]
            ++ (lib.attrValues self.overlays);
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
        inherit pkgs lib nixpkgs nixpkgs-stable;
        packages = self.packages;
      };

      packages = forAllSystems
        (system: mapModules ./packages (p: pkgs.${system}.callPackage p { }));

      overlay = final: prev: {
        stable = nixpkgs-stable.legacyPackages.${prev.system};
        my = self.packages.${prev.system};
      };

      overlays = mapModules ./overlays import;

      darwinConfigurations =
        (lib.my.mapDarwinHosts "aarch64-darwin" ./hosts/aarch64-darwin);

      nixosConfigurations = lib.my.mapNixosHosts ./hosts/nixos;

      homeManagerConfigurations =
        lib.my.mapHomeManagerHosts "x86_64-linux" ./hosts/x86_64-linux;
    };
}
