msg "Set sudo to aways prompt for passwords"
${chroot} << CHROOT
sed -i 's/^\(%wheel ALL=(ALL) NOPASSWD: ALL\)/# \1/' /etc/sudoers
sed -i 's/^# \(%wheel ALL=(ALL) ALL\)/\1/' /etc/sudoers
CHROOT

msg "Set Passwords"
${chroot} << CHROOT
chpasswd << PASSWORDS
root:${pass_root}
${username}:${pass_user}
PASSWORDS
CHROOT

