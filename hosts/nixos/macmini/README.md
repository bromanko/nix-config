# NixOS on a Mac Mini

This is a guide to configuring my Mac Mini to run NixOS.

## Building the LiveCD

You must first build the LiveCD to install NixOS on the Mac Mini. This must be built on a Linux
x86-64 machine so I use a docker container (enumated via the legacy QEMU virtual machine).

```bash
docker run --platform linux/amd64 --rm -it -v .:/code nixos/nix
```
Inside the docker container you must disable the syscall filtering in order to build:

```bash
echo "filter-syscalls = false" >> /etc/nix/nix.conf
```

Then run the command to build the ISO:

```bash
nix --extra-experimental-features "nix-command flakes" build .#isoConfigurations.macmini.config.system.build.isoImage

l ./result
```
This result path is a symlink to a location outside of the mounted directory. Make sure to copy over the file so that it can be accessed
from the host machine.
