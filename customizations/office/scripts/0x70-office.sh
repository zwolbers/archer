msg "Install packages"
${chroot} << CHROOT
pacman --noconfirm --needed -S \
    abiword \
    aspell-en \
    evince \
    hunspell-en_US \
    hyphen-en \
    libreoffice-fresh \
    mythes-en
CHROOT

