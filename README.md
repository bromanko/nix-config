# bromanko's Nix Configuration

This is my Nix configuration. It supports both my macOS and Linux system configurations.
It leverages [home-manager](https://rycee.gitlab.io/home-manager/) and
[nix-darwin](https://daiderd.com/nix-darwin/manual/index.html).

## Usage

### Requirements

Nix and Flakes must be installed in order to build the derivations. Running the included `./install-nix.sh` script
will set those up.

### Building

You can now build a system configuration by running `nix build` and specifying the configuration target:

For `nix-darwin` (macOS):
```sh
nix build .#darwinConfigurations.PersonalMacbookPro.system
```

For `home-manager` (Linux):

``` sh
nix build .#workDevServer.activationPackage
```

Results will be placed in the `result` folder.

### Applying

Once the derivation is build you can apply it via the `nix-darwin` or `home-manager` installation command.

For `nix-darwin` (macOS):

``` sh
./result/sw/bin/darwin-rebuild switch --flake .#personalMacbookPro
```

For `home-manager` (Linux):

``` sh
./result/sw/bin/activate 
```

## References

This setup is heavily inspired by [malob's](https://github.com/malob/nixpkgs) excellent nixpkgs configuration. 
