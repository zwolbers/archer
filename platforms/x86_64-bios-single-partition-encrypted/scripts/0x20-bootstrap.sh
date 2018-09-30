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
# Note: the name of this script is a bit of a lie.  There are two
# partitions: one for the bootloader, and another for the root file system.
sfdisk -X dos ${sd} << PARTITION
,200M,,*
,,,
PARTITION

msg "Overwrite with random data"
cryptsetup open --type plain ${sd}2 container --key-file /dev/random
dd bs=1M if=/dev/zero of=/dev/mapper/container status=progress || true
cryptsetup close container

msg "Create a LUKS Container"
echo -n ${pass_root} | cryptsetup -v luksFormat --type luks2 ${sd}2 -
echo -n ${pass_root} | cryptsetup open ${sd}2 cryptroot

msg "Format"
mkfs.ext4 ${sd}1
mkfs.ext4 /dev/mapper/cryptroot

msg "Mount"
mount /dev/mapper/cryptroot /mnt
mkdir /mnt/boot
mount ${sd}1 /mnt/boot

msg "Install base packages"
pacstrap /mnt base

msg "Generate /etc/fstab"
genfstab -U /mnt >> /mnt/etc/fstab

msg "Update initramfs"
${chroot} << CHROOT
sed -i 's/^\(HOOKS=(.*\)block\(.*)\)/\1keyboard block encrypt\2/' /etc/mkinitcpio.conf
mkinitcpio -p linux
CHROOT

msg "Install GRUB"
${chroot} << CHROOT
pacman --noconfirm -S grub
sed -i 's/^\(GRUB_CMDLINE_LINUX=\)""/\1"cryptdevice=UUID='$(blkid -s UUID -o value ${sd}2)':cryptroot:allow-discards root=\/dev\/mapper\/cryptroot"/' /etc/default/grub
grub-install --target=i386-pc ${sd}
grub-mkconfig -o /boot/grub/grub.cfg
CHROOT

