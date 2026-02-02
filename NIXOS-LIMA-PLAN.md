# NixOS Lima Dev VM — Research & Implementation Plan

## Current State

The existing `dev.yaml` uses a **hybrid approach**:
- Boots a NixOS ISO image (nixos-24.05 minimal)
- System provisioning clones nix-config to `/etc/nixos` and runs `nixos-rebuild switch`
- User provisioning installs Determinate Nix separately and activates a **standalone home-manager** config
- The host config at `hosts/aarch64-linux/lima-dev/default.nix` is a standalone HM config, not a NixOS system config

This means NixOS provides the kernel/base system, but user environment management is decoupled — essentially using NixOS as a fancy Ubuntu substitute.

## nixos-lima Project (github.com/nixos-lima/nixos-lima)

### What It Provides

1. **Pre-built qcow2 images** — NixOS images designed specifically for Lima (v0.0.3 latest, Aug 2025)
2. **NixOS module** (`nixosModules.lima`) with two systemd services:
   - `lima-init` — reads Lima's cidata at boot, creates user, sets up SSH keys, mounts, runs provision scripts
   - `lima-guestagent` — port forwarding daemon (supports both QEMU and VZ/vsock)
3. **VZ (Virtualization.framework) support** — merged recently, works with `vmType: "vz"`
4. **qemu-guest profile** — hardware config for Lima's virtual hardware

### How It Works

1. Lima boots the qcow2 image
2. Lima attaches a cidata ISO with user info, SSH keys, mount definitions, provision scripts
3. `lima-init` systemd service reads cidata and configures the system (user creation, SSH, fstab mounts)
4. `lima-guestagent` starts port forwarding
5. You then `nixos-rebuild` with your own flake to customize

### Key Architecture Decision

The nixos-lima project separates concerns:
- **Base image** = minimal NixOS + Lima integration module (generic, reusable)
- **User configuration** = your own flake with `nixosConfigurations` that imports `nixos-lima.nixosModules.lima`

Two deployment models:
1. **From inside the VM**: clone config repo to `/etc/nixos`, run `nixos-rebuild switch`
2. **From the host**: `limactl shell nixos -- nixos-rebuild boot --flake .#config-name --sudo` (leverages Lima's home directory mount)

## Proposed Architecture for nix-config

### Add `nixos-lima` as a Flake Input

```nix
inputs.nixos-lima = {
  url = "github:nixos-lima/nixos-lima";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### New NixOS Host: `hosts/aarch64-linux/lima-nixos-dev/`

A proper **NixOS system configuration** (not standalone HM) that:

```nix
{ config, modulesPath, pkgs, lib, nixos-lima, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    nixos-lima.nixosModules.lima
  ];

  services.lima.enable = true;

  # Boot (matches nixos-lima image layout)
  boot.loader.grub = {
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  fileSystems."/boot".device = lib.mkForce "/dev/vda1";
  fileSystems."/".device = "/dev/disk/by-label/nixos";

  # System services (currently done imperatively)
  # - privoxy for network lockdown
  # - openssh
  # - networking

  # Home-manager as NixOS module (not standalone)
  # Uses the existing hosts/nixos.nix base which already imports
  # home-manager.nixosModules.home-manager
}
```

### New Lima Template: `configs/lima/dev-nixos.yaml`

```yaml
vmType: "vz"
os: "Linux"
arch: "default"

images:
  - location: "https://github.com/nixos-lima/nixos-lima/releases/download/v0.0.3/nixos-lima-v0.0.3-aarch64.qcow2"
    arch: "aarch64"
    digest: "sha512:809bd6bf46e27719eb69cc248e31a6c98725415976f8f0111b86228148a4379ea05e7405930c086487c9d51961e8776f61744175f33423ce3508e74a7f1a87c4"
  - location: "https://github.com/nixos-lima/nixos-lima/releases/download/v0.0.3/nixos-lima-v0.0.3-x86_64.qcow2"
    arch: "x86_64"
    digest: "sha512:d7e6a9c9519d94e006af40f689b98c235624bcc5c32f13ad4fe6c6ae411db4a1d6f5415135cd06665fc6eccd4c857d64512c28ec76cd04bfdfbd791408c57eb6"

cpus: 4
memory: "8GiB"
disk: "100GiB"

mounts:
  - location: "~"
    writable: false
    9p:
      cache: "mmap"
  - location: "/tmp/lima"
    writable: true
    9p:
      cache: "mmap"

containerd:
  system: false
  user: false

provision:
  - mode: system
    script: |
      #!/bin/bash
      set -eux -o pipefail
      # Clone nix-config if not present
      if [ ! -d /etc/nixos/nix-config ]; then
        git clone https://github.com/bromanko/nix-config.git /etc/nixos/nix-config
      fi
      # Rebuild with the NixOS flake config
      cd /etc/nixos/nix-config
      nixos-rebuild switch --flake .#lima-nixos-dev

portForwards:
  - guestPortRange: [1024, 65535]
    hostPortRange: [1024, 65535]

ssh:
  loadDotSSHPubKeys: true
  forwardAgent: true
```

### Key Differences from Current Setup

| Aspect | Current (lima-dev) | Proposed (lima-nixos-dev) |
|--------|-------------------|--------------------------|
| Base image | NixOS ISO (raw) | nixos-lima qcow2 (Lima-ready) |
| Lima integration | Manual (provision scripts) | `services.lima.enable = true` (systemd) |
| Guest agent | None/manual | `lima-guestagent` systemd service |
| User management | Standalone home-manager | HM as NixOS module |
| System services | Imperative (provision scripts) | Declarative NixOS modules |
| Rebuild | `nix build ...#homeManagerConfigurations.lima-dev.activationPackage` | `nixos-rebuild switch --flake .#lima-nixos-dev` |
| Privoxy/network | Imperative setup in provision | NixOS `services.privoxy` module |
| Host-side rebuild | Not supported | `limactl shell -- nixos-rebuild switch --flake .#config` |

### Changes Needed in lib/hosts.nix

`mkNixosHost` is currently hardcoded to `x86_64-linux`. Need to parameterize:

```nix
mkNixosHost = system: path:
  nixosSystem {
    specialArgs = { inherit lib inputs; };
    system = system;
    modules = [ ... ];
  };
```

And update `flake.nix` to:
- Pass `nixos-lima` through `specialArgs`
- Add `nixosConfigurations` output
- Map NixOS hosts from `hosts/aarch64-linux/` (with some way to distinguish NixOS hosts from HM-only hosts)

### Implementation Steps

1. Add `nixos-lima` flake input
2. Generalize `mkNixosHost` to accept a `system` parameter
3. Create `hosts/aarch64-linux/lima-nixos-dev/default.nix` as NixOS system config
4. Move system-level concerns (privoxy, networking, users) into NixOS modules under `modules/linux/`
5. Create `configs/lima/dev-nixos.yaml` using nixos-lima qcow2 images
6. Add to `modules/home-manager/dev/lima.nix` so the template is deployed
7. Wire up `nixosConfigurations` in `flake.nix`
8. Test: create VM, provision, verify all tools work
9. Once stable, migrate and deprecate old config

### Open Questions

1. **Home directory mount** — nixos-lima mounts `~` read-only by default (9p). The current setup uses Lima's default writable mounts. Need to decide: writable home mount for host-side editing, or read-only with `/tmp/lima` writable?
2. **Rebuild workflow** — From host (`limactl shell -- nixos-rebuild`) vs from inside VM (`ssh in, nixos-rebuild`)? The host-side approach is nice because `~` is mounted and the flake is accessible.
3. **NixOS host vs HM host disambiguation** — Currently `hosts/aarch64-linux/` contains HM-only hosts. Need a convention to tell NixOS hosts apart (subdirectory convention? marker file? separate directory tree like `hosts/nixos/aarch64-linux/`?).
4. **9p vs virtiofs** — nixos-lima defaults to 9p mounts. Lima with VZ can use virtiofs which is faster. Worth investigating.
