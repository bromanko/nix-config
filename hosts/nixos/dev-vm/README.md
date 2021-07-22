# Dev

This is s VMWare virtual machine used for development work.

## VMWare VM Configuration

#### Processors & Memory

- Assign half of the main machine cores and memory
- Under "Advanced", check "Enable hypervisor applications in the virtual machine".

#### Display

- Check "Accelerate 3D Graphics" and select the recommended "Shared graphics memory"
- Check "Use full resolution for Retina display"
- Choose "All View Modes" for "Scaled high resolution"

#### Advanced

- Check "Synchronize time"
- Check "Pass power status to VM"
- Check "Disable Side Channel Mitigations"

## Preparing the Disk

### Partitioning

```sh
# 30GB expanding disk

parted /dev/sda -- mklabel gpt # Partition table
parted /dev/sda -- mkpart primary 512MiB -8GiB # Root partition (all space except swap)
parted /dev/sda -- mkpart primary linux-swap -8GiB 100% # 8GB swap
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB # 512MB boot partition
parted /dev/sda -- set 3 esp on
```

### Formatting

```sh
mkfs.ext4 -L nixos /dev/sda1 # Root partition
mkswap -L swap /dev/sda2 # Swap partition
mkfs.fat -F 32 -n boot /dev/sda3 # Boot partition
```

### Mounting

```sh
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2
```
