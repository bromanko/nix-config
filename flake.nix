{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-21.11";

    # System management
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
    };

    # Other sources
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    homeage = {
      # Waiting for https://github.com/jordanisaacs/homeage/pull/43 to land
      url = "github:jordanisaacs/homeage/pull/43/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    age-plugin-op = {
      url = "github:bromanko/age-plugin-op";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, darwin, home-manager
    , emacs-overlay, age-plugin-op, brew-nix, ... }:
    let
      inherit (lib.my) mapModules;

      supportedSystems = [ "aarch64-darwin" "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.input-fonts.acceptLicense = true;
          overlays =
            [ self.overlay brew-nix.overlays.default emacs-overlay.overlay ]
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
        inherit pkgs lib;
        packages = self.packages;
      };

      packages = forAllSystems
        (system: mapModules ./packages (p: pkgs.${system}.callPackage p { }));

      overlay = final: prev: {
        stable = nixpkgs-stable.legacyPackages.${prev.system};
        my = self.packages.${prev.system} // {
          age-plugin-op = age-plugin-op.defaultPackage.${prev.system};
        };
      };

      overlays = mapModules ./overlays import;

      darwinConfigurations =
        (lib.my.mapDarwinHosts "aarch64-darwin" ./hosts/aarch64-darwin);

      nixosConfigurations = lib.my.mapNixosHosts ./hosts/nixos;

      homeManagerConfigurations =
        lib.my.mapHomeManagerHosts "x86_64-linux" ./hosts/x86_64-linux;
    };
}
