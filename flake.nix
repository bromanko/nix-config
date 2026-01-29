{
  description = "bromanko's Nix system config";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/master";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System management
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    darwin = {
      url = "github:nix-darwin/nix-darwin";
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
    dealmail = {
      url = "https://flakehub.com/f/bromanko/dealmail/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nur,
      home-manager,
      emacs-overlay,
      age-plugin-op,
      ...
    }:
    let
      inherit (lib.my) mapModules;

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
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
      packages = forAllSystems (
        system:
        let
          allPkgs = mapModules ./packages (p: pkgs.${system}.callPackage p { });
        in
        lib.filterAttrs (
          _: pkg:
          let
            platforms = pkg.meta.platforms or lib.platforms.all;
          in
          lib.elem system platforms
        ) allPkgs
      );

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShell {
          packages = with pkgs.${system}; [
            nixfmt
          ];
        };
      });

      formatter = forAllSystems (system: pkgs.${system}.nixfmt-tree);

      checks = forAllSystems (
        system:
        let
          pkgsForSystem = pkgs.${system};
        in
        {
          formatting =
            pkgsForSystem.runCommand "check-formatting"
              {
                nativeBuildInputs = [
                  pkgsForSystem.nixfmt
                  pkgsForSystem.findutils
                ];
                src = self;
              }
              ''
                cd $src
                find . -name '*.nix' -type f -exec nixfmt --check {} +
                touch $out
              '';
        }
        # Darwin configs (aarch64-darwin only)
        // lib.optionalAttrs (system == "aarch64-darwin") (
          lib.mapAttrs' (
            name: config: lib.nameValuePair "darwin-${name}" config.config.system.build.toplevel
          ) self.darwinConfigurations
        )
        # Home Manager configs - filter by system
        // (
          let
            hmConfigsBySystem = {
              "x86_64-linux" = lib.my.mapHomeManagerHosts "x86_64-linux" ./hosts/x86_64-linux;
              "aarch64-linux" = lib.my.mapHomeManagerHosts "aarch64-linux" ./hosts/aarch64-linux;
            };
          in
          lib.mapAttrs' (name: config: lib.nameValuePair "hm-${name}" config.activationPackage) (
            hmConfigsBySystem.${system} or { }
          )
        )
      );

      overlays = mapModules ./overlays import // {
        default = final: prev: {
          my = self.packages.${prev.stdenv.hostPlatform.system} // {
            age-plugin-op = age-plugin-op.defaultPackage.${prev.stdenv.hostPlatform.system};
          };
        };
      };

      darwinConfigurations = (lib.my.mapDarwinHosts "aarch64-darwin" ./hosts/aarch64-darwin);

      homeManagerConfigurations =
        (lib.my.mapHomeManagerHosts "x86_64-linux" ./hosts/x86_64-linux)
        // (lib.my.mapHomeManagerHosts "aarch64-linux" ./hosts/aarch64-linux);
    };
}
