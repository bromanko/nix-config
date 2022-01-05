{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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

  outputs =
    inputs@{ self, nixpkgs, nixpkgs-unstable, darwin, home-manager, ... }:
    let
      inherit (lib.my) mapModules mapModulesRec;

      supportedSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      pkgs = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlay ] ++ (lib.attrValues self.overlays)
            ++ (lib.optional (system == "aarch64-darwin") self.aarch64Overlays);
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
        inherit pkgs lib nixpkgs nixpkgs-unstable;
        packages = self.packages;
      };

      packages = forAllSystems
        (system: mapModules ./packages (p: pkgs.${system}.callPackage p { }));

      overlay = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        my = self.packages.${prev.system};
      };

      overlays = mapModules ./overlays import;

      aarch64Overlays = self: super: {
        # Need ghc
        shellcheck = pkgs.x86_64-darwin.shellcheck;
        nixfmt = pkgs.x86_64-darwin.nixfmt;

        # https://github.com/NixOS/nixpkgs/issues/127902
        emacsMacport = pkgs.x86_64-darwin.emacsMacport;

        # Can't compile on Monterey
        kitty = super.kitty.overrideAttrs (old: rec { });
      };

      darwinConfigurations =
        (lib.my.mapDarwinHosts "x86_64-darwin" ./hosts/x86_64-darwin)
        // (lib.my.mapDarwinHosts "aarch64-darwin" ./hosts/aarch64-darwin);

      nixosConfigurations = lib.my.mapNixosHosts ./hosts/nixos;

      homeManagerConfigurations =
        lib.my.mapHomeManagerHosts "x86_64-linux" ./hosts/x86_64-linux;
    };
}
