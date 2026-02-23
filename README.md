# bromanko's Nix Configuration

This is my Nix configuration. It supports my macOS, nixOS, and home-manager configurations.

## Usage

### Requirements

Nix and Flakes must be installed in order to build the derivations. I recommend using the [Determinate Nix Installer](https://determinate.systems/oss/).

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

### Building and Applying

You can now build a system configuration by running `nix build` and specifying the configuration target:

For `nix-darwin` (macOS):

```sh
nix build .#darwinConfigurations.bromanko-personal-mbp.system
./result/sw/bin/darwin-rebuild switch --flake .#bromanko-personal-mbp
```

For `nixos`:

```sh
nixos-rebuild switch --flake .#nixosConfigurations.dev-vm
```

### Hetzner host for Michael (always-on)

A dedicated host config exists at:

- `hosts/nixos/x86_64-linux/sleeper-service/default.nix`

Provisioning automation and runbook are in this repo:

- `scripts/hetzner/create-server.sh`
- `scripts/hetzner/bootstrap-nixos.sh`
- `scripts/hetzner/apply-host-config.sh`
- `docs/runbooks/sleeper-service-provisioning.md`

Quick flow:

```sh
scripts/hetzner/create-server.sh
scripts/hetzner/bootstrap-nixos.sh <server-ip>
INSTALL_BOOTLOADER=1 scripts/hetzner/apply-host-config.sh <server-ip> sleeper-service
# later applies: scripts/hetzner/apply-host-config.sh <server-ip> sleeper-service
```

This host is designed for one always-on Michael process (API + static frontend + in-process calendar sync), with a separate systemd timer for SQLite backups.

Backups are written locally to `/var/lib/michael/backups` and can be uploaded offsite to S3-compatible object storage by creating `/var/lib/michael/backup-upload.env` (see `docs/runbooks/sleeper-service-provisioning.md`).

For `home-manager`:

```sh
nix build .#homeManagerConfigurations.fb-devserver.activationPackage
./result/activate
```

### Home Manager Configuration

The home-manager configuration is decoupled from the nixos or Darwin modules. This allows me to use the same config for both environments managed by nixos/nix-darwin and plain home-manager. Unfortunately it makes the organization of modules messy. The modules defining home-manager options must be in separate files from the config itself. This is because I need to import the home-manager config manually outside of the module loading process.

- The `/home-manager` folder contains the home-manager config and will get imported under a `home-manager` option.
- The `/modules/home-manager` folder contains the options for enabling home-manager configuration.

## References

This setup is heavily inspired by:

- [malob's](https://github.com/malob/nixpkgs) excellent nixpkgs configuration.
- [hlissner's dotfiles](https://github.com/hlissner/dotfiles)
