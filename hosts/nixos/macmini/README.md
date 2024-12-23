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

Now the LiveCD must be written to a USB drive. First, find the USB drive:

```bash
diskutil list
```

Look for the USB drive in the output. It will typically be listed as something like /dev/disk2,
/dev/disk3, etc. Make sure to note the correct disk identifier (not a partition number like
disk2s1).

Now unmount the USB drive:

```bash
diskutil unmountDisk /dev/diskX
```

Now write the ISO to the USB drive:

```bash
sudo dd if=/path/to/result.iso of=/dev/diskX bs=1m status=progress
```

* `if` is the path to the ISO file
* `of` is the path to the USB drive
* `bs` is the block size
* `status` is the progress status

This will take a while to complete. Once it is done, eject the USB drive:

```bash
diskutil eject /dev/diskX
```

## Installing NixOS

This process follows instructions from [this blog post](https://www.arthurkoziel.com/installing-nixos-on-a-macbookpro/).

1. Boot the Mac Mini from the USB drive. You may need to hold down the `Option` key while booting
   to select the USB drive.
2. Once booted you will need to format and mount the partitions.

```bash
# Create the filesystem
mkfs.ext4 /dev/sda3

# Mount the filesystem
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Create the swap partition
mkswap -L nixosswap /dev/sda4
swapon /dev/disk/by-label/nixosswap
```

At this point I would like to setup WiFi but I have not yet figured out how to do this. Instead, make sure ethernet is
connected and continue with the installation.

3. Generate the NixOS configuration:

```bash
nixos-generate-config --root /mnt
```

4. Edit the configuration file at `/mnt/etc/nixos/configuration.nix` to match the configuration in this directory.

5. Install NixOS:

```bash
nixos-install
```

## Apply Configuration

After the installation is complete, reboot the machine and login as the root user. Now you can apply the configuration:

```bash
nixos-rebuild switch --flake github:bromanko/nix-config#macmini
```
