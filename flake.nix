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
      inherit (lib.my) mapModules mapHosts;

      mkPkgs = system: pkgs: extraOverlays:
        import pkgs {
          system = system;
          config.allowUnfree = true;
          overlays = extraOverlays ++ (lib.attrValues self.overlays);
        };
      pkgs = mkPkgs "x86_64-linux" nixpkgs [ self.overlay ];
      pkgsDarwin = mkPkgs "x86_64-darwin" nixpkgs-darwin [ self.overlay ];
      pkgs' = mkPkgs "x86_64-linux" nixpkgs-unstable [ ];

      # nixpkgsConfig = with inputs; {
      #   config.allowUnfree = true;
      #   overlays = self.overlays ++ [
      #     (final: prev:
      #       let
      #         system = prev.stdenv.system;
      #         nixpkgs-stable = if system == "x86_64-darwin" then
      #           nixpkgs-stable-darwin
      #         else
      #           nixos-stable;
      #       in {
      #         master = nixpkgs-master.legacyPackages.${system};
      #         stable = nixpkgs-stable.legacyPackages.${system};
      #       })
      #   ];
      # };

      # Modules shared between nix-darwin and plain home-manager
      # homeManagerCommonConfig = with self.homeManagerModules; {
      #   imports = [ ./home configs.starship.symbols ];
      # };

      # Modules shared by nix-darwin configurations
      # nixDarwinCommonModules = { user }: [
      #   ./darwin
      #   home-manager.darwinModules.home-manager
      #   {
      #     nixpkgs = nixpkgsConfig;
      #     # Hack to support legacy workflows that use <nixpkgs>
      #     nix.nixPath = { nixpkgs = "$HOME/.config/nixpkgs/nixpkgs.nix"; };
      #     users.users.${user}.home = "/Users/${user}";
      #     home-manager.useGlobalPkgs = true;
      #     home-manager.users.${user} = homeManagerCommonConfig;
      #   }
      # ];

      lib = nixpkgs.lib.extend (self: super: {
        my = import ./lib {
          inherit pkgs inputs;
          lib = self;
        };
      });

    in {
      # For repl debugging
      passtru = { inherit lib; };

      overlay = final: prev: { unstable = pkgs'; };

      overlays = mapModules ./overlays import;

      # nixosConfigurations = mapHosts ./hosts/nixos { };
      darwinConfigurations = lib.mapAttrs (n: v: (darwin.lib.darwinSystem v))
        (mapHosts ./hosts/darwin);

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
