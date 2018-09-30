msg "Install packages"
${chroot} << CHROOT
pacman --noconfirm --needed -S \
    chromium \
    firefox \
    keepassxc \
    pepper-flash \
    syncthing-gtk
CHROOT

msg "Use SSH for git projects"
${chroot_user} << CHROOT_USER
cd ~/Projects/dotfiles/
git remote set-url origin git@github.com:zwolbers/dotfiles.git
CHROOT_USER

