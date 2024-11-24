# NixOS on a Mac Mini

This is a guide to configuring my Mac Mini to run NixOS.

## Building the LiveCD

You must first build the LiveCD to install NixOS on the Mac Mini. This must be built on a Linux
machine so I tend to use UTM for this. Download a [NixOS ISO](https://nixos.org/download/) and
configure the VM to boot from the ISO. Map a shared folder to the folder containing this repo.
Then, in the VM, run the following command to build the ISO:

```bash
nix build .#isoConfigurations.macmini.config.system.build.isoImage
```
