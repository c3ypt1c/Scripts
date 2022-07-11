#!/bin/bash

# Settings
source Settings.sh

# localisation (change this if you don't live in the uk) (timedatectl list-timezones | YOUR CAPITAL)
echo "Upating Localisation"

# set the clocks
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# this is needed for steam (or else you'll get funny characters in csgo)
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

# change this line below if you don't live in the uk
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen
# change this to your language string
echo LANG=en_GB.UTF-8 >> /etc/locale.conf

# change this to your keyboard map
echo KEYMAP=uk >> /etc/vconsole.conf

# set the hostname for the machine
echo $MACHINE_NAME >> /etc/hostname

# setting up hosts
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1" $MACHINE_NAME >> /etc/hosts

# change pacman stuff
echo "Set up pacman config"

# enable multilib
sed -i "s/\#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/" /etc/pacman.conf

# enable color
sed -i "s/\#Color/Color/" /etc/pacman.conf

#enable parallel downloads
sed -i "s/\#ParallelDownloads/ParallelDownloads/" /etc/pacman.conf


# finalising install
echo "Install and setup reflector"
pacman --noconfirm -Syyu reflector
# change c flag to your contry code
reflector -c GB --sort rate -a 10 -p https --save /etc/pacman.d/mirrorlist
pacman --noconfirm -Syyy


echo "Install most of the packages"
pacman --noconfirm -S grub efibootmgr network-manager-applet dialog os-prober mtools dosfstools base-devel linux-headers git wget cups xdg-utils xdg-user-dirs pulseaudio pavucontrol


# setting up grub
echo "Setting up grub"

# mkinitcpio
sed -i "s/HOOKS/\#HOOKS/g" /etc/mkinitcpio.conf
echo "HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems keyboard fsck)" >> /etc/mkinitcpio.conf
mkinitcpio -p linux

# install grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# get disk uuid
UUID_DISK2=$(blkid -s UUID -o value $DISK2)
NEW_GRUB_CMDLINE="GRUB_CMDLINE_LINUX=\"cryptdevice=UUID="$UUID_DISK2":cryptlvm root=/dev/vg1/root\""

sed -i "s/GRUB_CMDLINE_LINUX=\"\"/#GRUB_CMDLINE_LINUX (it was empty)/" /etc/default/grub 
echo $NEW_GRUB_CMDLINE >> /etc/default/grub  

# gen grub
grub-mkconfig -o /boot/grub/grub.cfg


echo "Enabling services"
systemctl enable NetworkManager
systemctl enable cups


# setting up users
echo "New root password"
passwd

echo "Creating new user"
useradd -mG wheel $ADMIN_USER

echo "New user password"
passwd $ADMIN_USER


# adding wheel to users
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "Done! Now leaving chroot..."
exit