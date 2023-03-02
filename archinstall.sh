#!/bin/bash

# Update the system clock
timedatectl set-ntp true

# Partition the disk
# Replace /dev/sda with your disk device
(
  echo g; # Create a new empty GPT partition table
  echo n; # Create a new partition
  echo 1; # Partition number (default is 1)
  echo 2048; # First sector (default is 2048)
  echo +512M; # Last sector for EFI system partition
  echo t; # Change partition type
  echo 1; # EFI System partition
  echo n; # Create a new partition
  echo ; # Partition number (default is 2)
  echo ; # First sector (default is next free sector)
  echo ; # Last sector (default is entire disk)
  echo t; # Change partition type
  echo 2;  # Select Pertition
  echo 20; # Linux Filesystem
  echo w; # Write changes to disk
) | fdisk /dev/sda

# Format the partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount the partitions
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Install the base system
pacstrap /mnt base linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF

# Set the timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Set the hostname
echo "arch" > /etc/hostname

# Generate the locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set the root password
echo "root:password" | chpasswd

# Install Xorg and other packages
pacman -S xorg xorg-xinit --noconfirm

# Install the systemd boot manager
bootctl install

# Configure the boot manager
cat <<EOF2 > /boot/loader/loader.conf
default arch
timeout 0
EOF2

cat <<EOF2 > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=/dev/sda2 rw
EOF2

EOF

# Unmount partitions and reboot
umount -R /mnt

