#!/usr/bin/bash

set -euxo pipefail

# Enable services. GDM was pulled in as a dependent removal in 00-packages.sh
# so it doesn't need disabling here.

systemctl enable nix.mount
systemctl enable nix-daemon.service
systemctl enable greetd
systemctl enable pcscd.socket
systemctl enable mullvad-daemon.service

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
