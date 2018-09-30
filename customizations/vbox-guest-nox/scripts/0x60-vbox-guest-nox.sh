msg "Install packages"
${chroot} << CHROOT
pacman --noconfirm --needed -S virtualbox-guest-utils-nox virtualbox-guest-modules-arch
gpasswd -a ${username} vboxsf
systemctl enable vboxservice.service
CHROOT

