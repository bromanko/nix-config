{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-21.11";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System management
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Other sources
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    age-plugin-op = {
      url = "github:bromanko/age-plugin-op";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jujutsu = {
      url = "github:jj-vcs/jj";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeage = {
      url = "github:bromanko/homeage/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-stable,
      nur,
      determinate,
      home-manager,
      emacs-overlay,
      age-plugin-op,
      jujutsu,
      ...
    }:
    let
      inherit (lib.my) mapModules;

      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      pkgs = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.input-fonts.acceptLicense = true;
          overlays = [
            self.overlay
            nur.overlays.default
            emacs-overlay.overlay
          ]
          ++ (lib.attrValues self.overlays);
        }
      );

      lib = nixpkgs.lib.extend (
        self: super: {
          my = import ./lib {
            inherit pkgs inputs home-manager;
            lib = self;
          };
          hm = home-manager.lib.hm;
        }
      );
    in
    {
      # For debugging
      passthru = {
        inherit pkgs lib;
        packages = self.packages;
      };

      packages = forAllSystems (system: mapModules ./packages (p: pkgs.${system}.callPackage p { }));

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShell {
          packages = with pkgs.${system}; [
            nixfmt-rfc-style
          ];
        };
      });

      overlay = final: prev: {
        stable = nixpkgs-stable.legacyPackages.${prev.system};
        jujutsu = jujutsu.packages.${prev.system}.jujutsu;
        my = self.packages.${prev.system} // {
          age-plugin-op = age-plugin-op.defaultPackage.${prev.system};
        };
      };

      overlays = mapModules ./overlays import;

      darwinConfigurations = (lib.my.mapDarwinHosts "aarch64-darwin" ./hosts/aarch64-darwin);

      nixosConfigurations = lib.my.mapNixosHosts ./hosts/nixos;

      homeManagerConfigurations = lib.my.mapHomeManagerHosts "x86_64-linux" ./hosts/x86_64-linux;

      isoConfigurations = lib.my.mapNixosIsos ./hosts/iso;
    };
}
