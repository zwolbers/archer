msg "Install standard packages"
${chroot} << CHROOT
pacman --noconfirm --needed -S \
    base-devel \
    avahi \
    bash-completion \
    bat \
    ctags \
    fd \
    git \
    hdparm \
    htop \
    jq \
    lshw \
    mlocate \
    neovim \
    networkmanager \
    nss-mdns \
    openssh \
    pacman-contrib \
    pacmatic \
    python \
    python-pip \
    python-html2text \
    rsync \
    ruby \
    ruby-rdoc \
    sshfs \
    stow \
    tldr \
    tmux \
    tree \
    ufw \
    wget
CHROOT

msg "Set the Timezone"
${chroot} << CHROOT
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime
hwclock --systohc
CHROOT
cat << TODO >> working/messages
TODO: Enable time synchronization after reboot:
        # timedatectl set-ntp true
TODO

msg "Set Locale"
${chroot} << CHROOT
sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
CHROOT

msg "Set the hostname"
${chroot} << CHROOT
echo "${hostname}" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain ${hostname}
HOSTS
CHROOT

msg "Configure pacman"
${chroot} << CHROOT
sed -i 's|^#\(NoExtract\).*|\1 = etc/pacman.d/mirrorlist etc/locale.gen|' /etc/pacman.conf
sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
sed -i 's/^#\(TotalDownload\)/\1/' /etc/pacman.conf
sed -i 's/^#\(VerbosePkgLists\)/\1/' /etc/pacman.conf

if lscpu | grep "x86_64"; then
    patch /etc/pacman.conf << PACMAN_PATCH
@@ -90,8 +90,8 @@
 #[multilib-testing]
 #Include = /etc/pacman.d/mirrorlist

-#[multilib]
-#Include = /etc/pacman.d/mirrorlist
+[multilib]
+Include = /etc/pacman.d/mirrorlist

 # An example of a custom package repository.  See the pacman manpage for
 # tips on creating your own repositories.
PACMAN_PATCH
fi

systemctl enable paccache.timer
CHROOT

msg "Initialize pacmatic"
${chroot} << CHROOT
pacmatic -Sy >> /dev/null
CHROOT

msg "Setup Microcode (if Intel)"
${chroot} << CHROOT
if grep "vendor_id.*GenuineIntel" /proc/cpuinfo; then
    pacman -S --noconfirm --needed intel-ucode
fi
CHROOT

msg "Setup TRIM (if SSD)"
${chroot} << CHROOT
if hdparm -I ${sd} | grep TRIM; then
    systemctl enable fstrim.timer
fi
CHROOT

msg "Remap Caps Lock"
${chroot} << CHROOT
gzip -cd /usr/share/kbd/keymaps/i386/qwerty/us.map.gz \
    | sed 's/^\(keycode  58 = \)Caps_Lock/\1Escape/' \
    | gzip > /usr/share/kbd/keymaps/i386/qwerty/us-caps-lock.map.gz
echo "KEYMAP=us-caps-lock" > /etc/vconsole.conf
CHROOT

msg "Create a Swapfile (Size of Ram + 2%)"
${chroot} << CHROOT
fallocate -l \$(free -b | awk '/Mem/ {print int(\$2 * 1.02)}') /swapfile
chmod 600 /swapfile
mkswap /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab
CHROOT

msg "Setup network"
${chroot} << CHROOT
systemctl enable NetworkManager.service
CHROOT

msg "Configure ufw"
${chroot} << CHROOT
ufw default deny
ufw enable
systemctl enable ufw.service
CHROOT

msg "Setup mDNS hostname resolution"
${chroot} << CHROOT
sed -i 's/^\(hosts: .*\)\(resolve .*\)$/\1mdns_minimal [NOTFOUND=return] \2/' /etc/nsswitch.conf
systemctl enable avahi-daemon.service
ufw allow Bonjour
CHROOT

msg "Initialize mlocate"
${chroot} << CHROOT
updatedb
CHROOT

msg "Temporarily disable passwords for sudo"
${chroot} << CHROOT
sed -i 's/^# \(%wheel ALL=(ALL) NOPASSWD: ALL\)/\1/' /etc/sudoers
CHROOT

msg "Create User"
${chroot} << CHROOT
groupadd ${username}
useradd -mg ${username} -G wheel,sys ${username}
CHROOT

msg "Setup Dotfiles"
${chroot} << CHROOT
mkdir ~/Projects/
cd ~/Projects
git clone https://github.com/zwolbers/dotfiles.git
cd dotfiles
make
CHROOT

${chroot_user} << CHROOT_USER
rm ~/.bashrc ~/.bash_profile
mkdir ~/Projects/
cd ~/Projects
git clone https://github.com/zwolbers/dotfiles.git
cd dotfiles
make
CHROOT_USER

msg "Setup SSH"
if [[ ! -z "${ssh_port}" ]]; then
    echo "SSH Port: ${ssh_port}" >> working/messages
    ${chroot} << CHROOT
sed -i 's/^#\(Port\) 22/\1 ${ssh_port}/' /etc/ssh/sshd_config
ufw limit ${ssh_port}/tcp comment SSH
CHROOT
else
    ${chroot} << CHROOT
ufw limit SSH
CHROOT
fi

${chroot} << CHROOT
sed -i 's/^#\(LogLevel\) INFO/\1 VERBOSE/' /etc/ssh/sshd_config
sed -i 's/^#\(PermitRootLogin\) prohibit-password/\1 no/' /etc/ssh/sshd_config
sed -i 's/^#\(PasswordAuthentication\) yes/\1 no/' /etc/ssh/sshd_config

patch /etc/ssh/sshd_config << SSHD_PATCH
@@ -15,9 +15,18 @@
 #ListenAddress 0.0.0.0
 #ListenAddress ::

-#HostKey /etc/ssh/ssh_host_rsa_key
-#HostKey /etc/ssh/ssh_host_ecdsa_key
-#HostKey /etc/ssh/ssh_host_ed25519_key
+# Disable weaker algorithms
+# https://infosec.mozilla.org/guidelines/openssh
+# https://stribika.github.io/2015/01/04/secure-secure-shell.html
+KexAlgorithms curve25519-sha256@libssh.org
+Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
+MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
+
+HostKey /etc/ssh/ssh_host_ed25519_key
+HostKey /etc/ssh/ssh_host_rsa_key
+
+AuthenticationMethods publickey
+AllowGroups ssh-user

 # Ciphers and keying
 #RekeyLimit default none
SSHD_PATCH

groupadd ssh-user
gpasswd -a ${username} ssh-user

systemctl enable sshd.service
CHROOT

${chroot_user} << CHROOT_USER
cp ~/.ssh/id_ed25519.pub ~/.ssh/authorized_keys
cat << KNOWN_HOSTS > ~/.ssh/known_hosts
bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
KNOWN_HOSTS

chmod 700 ~/.ssh
chmod 600 ~/.ssh/{authorized_keys,known_hosts}
CHROOT_USER

msg "Setup neovim"
${chroot} << CHROOT
curl -sSfLo ~/.local/share/nvim/site/autoload/plug.vim \
    --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugInstall +qall
CHROOT

${chroot_user} << CHROOT_USER
curl -sSfLo ~/.local/share/nvim/site/autoload/plug.vim \
    --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugInstall +qall
CHROOT_USER

msg "Setup tmux"
${chroot_user} << CHROOT_USER
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
CHROOT_USER

msg "Install tmuxinator"
${chroot_user} << CHROOT_USER
gem install tmuxinator
~/.tmux/plugins/tpm/bin/install_plugins
CHROOT_USER

msg "Prepare for AUR"
${chroot_user} << CHROOT_USER
mkdir -p ~/.cache/aur
CHROOT_USER

