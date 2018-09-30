cat << README

Perform the bare minimum necessary to boot the system

# Verify internet connection

# Update the system clock
    timedatectl set-ntp true

# Select pacman mirrors
    echo "Server = https://mirrors.lug.mtu.edu/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

# Partition
    lsblk
    fdisk

# Format
    mkfs.ext4 /dev/sda1

# Mount
    mount /dev/sda1 /mnt/

# Install base packages
    pacstrap /mnt base

# Generate /etc/fstab
    genfstab -U /mnt >> /mnt/etc/fstab

# If needed, update working/chroot-settings.sh

# Generate a new initramfs if mkinitcpio.conf was updated
    arch-chroot /mnt mkinitcpio -p linux

# Install a bootloader
    arch-chroot /mnt pacman -S grub
    arch-chroot /mnt grub-install --target=i386-pc /dev/sdx
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

README

exit 1

