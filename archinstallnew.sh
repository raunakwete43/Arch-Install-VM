#!/bin/bash

# Set up variables
DISK="/dev/nvme0n1"
HOSTNAME="archlinux"
USERNAME="user"
PASSWORD="password"

# Partition the disk
parted -s $DISK mklabel gpt
parted -s $DISK mkpart primary fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ext4 513MiB 100%

# Format the partitions
mkfs.fat -F32 ${DISK}p1
mkfs.ext4 ${DISK}p2

# Mount the partitions
mount ${DISK}p2 /mnt
mkdir /mnt/boot
mount ${DISK}p1 /mnt/boot

# Install base packages and generate fstab file
pacstrap /mnt base linux linux-firmware vim networkmanager grub efibootmgr intel-ucode xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xorg-server xorg-apps xorg-xinit git curl wget 
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system and run some commands
arch-chroot /mnt <<EOF

# Set time zone and locale settings
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc --utc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 
locale-gen 
echo "LANG=en_US.UTF-8" > /etc/locale.conf 

# Set hostname and hosts file 
echo "$HOSTNAME" > /etc/hostname 
echo "127.0.0.1 localhost.localdomain localhost" > /etc/hosts 
echo "::1 localhost.localdomain localhost" >> /etc/hosts 
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts 

# Enable network manager service 
systemctl enable NetworkManager 

# Set root password 
echo "root:$PASSWORD" | chpasswd 

# Create a new user and add it to sudoers file 
useradd -m -g users -G wheel,storage,power,network,audio,video,optical,input "$USERNAME" 
echo "$USERNAME:$PASSWORD" | chpasswd 
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers 

# Install grub bootloader and update config file 
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB  
grub-mkconfig -o /boot/grub/grub.cfg 

# Enable lightdm display manager service 
systemctl enable lightdm 

EOF

# Unmount partitions and reboot system 
umount -R /mnt  
reboot 
