msg "Install driver"
${chroot} << CHROOT || echo "TODO: Install a display driver" >> working/messages
if lspci | grep -e VGA -e 3D | grep VirtualBox; then
    pacman --noconfirm --needed -S virtualbox-guest-utils virtualbox-guest-modules-arch
    gpasswd -a ${username} vboxsf
    systemctl enable vboxservice.service
else
    exit 1
fi
CHROOT

msg "Install packages"
${chroot} << CHROOT
pacman --noconfirm --needed -S \
    accountsservice \
    dconf-editor \
    dosfstools \
    file-roller \
    gparted \
    gtk-engine-murrine \
    gvfs \
    libva-mesa-driver \
    meld \
    mesa-vdpau \
    network-manager-applet \
    numix-gtk-theme \
    obconf \
    openbox \
    paprefs \
    pavucontrol \
    playerctl \
    pulseaudio \
    pulseaudio-alsa \
    pulseaudio-equalizer \
    pulseaudio-zeroconf \
    slock \
    ttf-dejavu \
    ttf-liberation \
    xdotool \
    xfce4 \
    xfce4-goodies \
    xorg \
    xsel
CHROOT

msg "Install compton (if needed)"
${chroot} << CHROOT
if ! lspci | grep -e VGA -e 3D | grep VirtualBox; then
    pacman --noconfirm --needed -S compton
fi
CHROOT

msg "Auto login"
${chroot} << CHROOT
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat << AUTOLOGIN > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${username} --noclear %I \$TERM
AUTOLOGIN
CHROOT

msg "Remap Caps Lock"
${chroot} << CHROOT
cat << CAPS > /etc/X11/xorg.conf.d/90-custom-kbd.conf
Section "InputClass"
    Identifier "keyboard defaults"
    MatchIsKeyboard "on"

    Option "XKbOptions" "caps:escape"
EndSection
CAPS
CHROOT

msg "Install icon themes"
# For security reasons, use a known revision
${chroot_user} << CHROOT_USER
cd ~/.cache/aur
git clone aur:numix-icon-theme-git
cd numix-icon-theme-git
git checkout 7ada913
makepkg --noconfirm -sic

cd ~/.cache/aur
git clone aur:numix-circle-icon-theme-git
cd numix-circle-icon-theme-git
git checkout a2a5ac6
makepkg --noconfirm -sic
CHROOT_USER

