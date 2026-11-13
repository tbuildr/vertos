#!/usr/bin/bash

set -euxo pipefail

# Enable services. GDM was pulled in as a dependent removal in 00-packages.sh
# so it doesn't need disabling here.

systemctl enable nix.mount
systemctl enable nix-daemon.service
systemctl enable greetd
systemctl enable pcscd.socket
systemctl enable mullvad-daemon.service

# Secret Service. Fedora 45 replaced gnome-keyring with oo7. oo7-daemon has no
# D-Bus activation by design and only gnome-session starts it, so enable it for
# every user session: pam_oo7 (in greetd's PAM stack) hands the login password
# to it at login. See linux-credentials/oo7#603.
systemctl --global enable oo7-daemon.service
test -L /etc/systemd/user/default.target.wants/oo7-daemon.service

# gcr ships GNOME's ssh-agent socket. The session uses Home Manager's ssh-agent
# (YubiKey askpass), so mask gcr's to avoid a second, keyless agent.
systemctl --global mask gcr-ssh-agent.socket gcr-ssh-agent.service
test "$(readlink /etc/systemd/user/gcr-ssh-agent.socket)" = /dev/null

# ClamAV signatures for clamscan-host (Home Manager). clamav-filesystem creates
# clamupdate via sysusers.d, but ships /var/lib/clamav only as image /var
# content, which existing deployments never receive: create it at boot.
printf 'd /var/lib/clamav 0755 clamupdate clamupdate -\n' >/usr/lib/tmpfiles.d/clamav-vertos.conf
systemctl enable clamav-freshclam.service

# --- firewall: vertos zone as default; fail the build if it isn't ---
# Replaces Fedora's default zone (Workstation-style zones open 1025-65535).
systemctl enable firewalld.service
grep -q '^DefaultZone=' /etc/firewalld/firewalld.conf
sed -i 's/^DefaultZone=.*/DefaultZone=vertos/' /etc/firewalld/firewalld.conf
firewall-offline-cmd --check-config
test "$(firewall-offline-cmd --get-default-zone)" = vertos
test "$(firewall-offline-cmd --zone=vertos --list-services)" = dhcpv6-client
test -z "$(firewall-offline-cmd --zone=vertos --list-ports)"
grep -qx 'LLMNR=no' /usr/lib/systemd/resolved.conf.d/50-no-llmnr.conf
