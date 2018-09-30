msg "Verify extra settings"
if [[ -z "${sd}" ]]; then
    err "Error: sd unset in settings.sh"
    exit 1
fi

msg "Verify internet connection"
ping -c 1 google.com

msg "Update the system clock"
timedatectl set-ntp true

msg "Select pacman mirrors"
> /etc/pacman.d/mirrorlist

if [[ ! -z "${paccache_ip}" ]] \
    || [[ ! -z "${paccache_port}" ]]; then
cat << MIRRORS >> /etc/pacman.d/mirrorlist
Server = ${paccache_ip}:${paccache_port}
MIRRORS
fi

cat << MIRRORS >> /etc/pacman.d/mirrorlist
Server = https://mirrors.lug.mtu.edu/archlinux/\$repo/os/\$arch
MIRRORS

msg "Partition"
echo ",,,*" | sfdisk -X dos ${sd}

msg "Format"
mkfs.ext4 ${sd}1

msg "Mount"
mount ${sd}1 /mnt

msg "Install base packages"
pacstrap /mnt base

msg "Generate /etc/fstab"
genfstab -U /mnt >> /mnt/etc/fstab

msg "Install GRUB"
${chroot} << CHROOT
pacman --noconfirm -S grub
grub-install --target=i386-pc ${sd}
grub-mkconfig -o /boot/grub/grub.cfg
CHROOT

