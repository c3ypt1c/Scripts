#!/bin/bash

# This is a very simple install script. It's also very opinionated.
# This script assumes that you have partitioned your disks. See start of this https://www.youtube.com/watch?v=kD3WC-93jEk

# Set your vars here (and in the other file too)
MACHINE_NAME="YourMachineNameHere"
DISK1="/dev/nvme0n1p1"
DISK2="/dev/nvme0n1p2"
ADMIN_USER="YourUsernameHere"


echo "Setting up encryption"
cryptsetup -y -v --type luks2 --iter-time 20000 --pbkdf argon2id luksFormat $DISK2
cryptsetup open $DISK2 cryptlvm


# lvm
echo "Setting up LVM"
pvcreate /dev/mapper/cryptlvm
vgcreate vg1 /dev/mapper/cryptlvm
lvcreate -L 200G vg1 -n root
lvcreate -l 75%FREE vg1 -n home


# formatting all the lvm
echo "Formatting partitions"
mkfs.fat -F32 $DISK1
mkfs.ext4 /dev/vg1/root
mkfs.btrfs /dev/vg1/home


# mounting all the drives
echo "Creating mounts"
mount /dev/vg1/root /mnt
mkdir /mnt/home
mount /dev/vg1/home /mnt/home
mkdir /mnt/boot
mount $DISK1 /mnt/boot


# progress
echo "=== Progress ==="
lsblk


# install (remove amd-ucode and replace with intel-ucode if you have intel)
echo "Installing arch base"
pacstrap /mnt base linux linux-firmware nano amd-ucode lvm2 networkmanager sudo


echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab


echo "Entering chroot"
cp ArchInstallerStage2.sh /mnt/ArchInstallerStage2.sh
arch-chroot /mnt bash /ArchInstallerStage2.sh

echo "Unmounting..."
umount -a

echo "Rebooting in 5s"
sleep 5 
reboot
