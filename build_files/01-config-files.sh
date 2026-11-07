#!/usr/bin/bash

set -euxo pipefail

# greetd-home.conf creates /var/lib/greetd on first boot.
#
# The greetd package ships /usr/lib/tmpfiles.d/greetd.conf, but its entry is:
#   Z  /var/lib/greetd -    greetd greetd -   -
# `Z` only recursively fixes ownership/permissions on a path that ALREADY
# exists - it never creates one. On ostree/bootc builds the directory isn't
# there, so nothing creates it and greetd has no home. Ours uses `d`, which
# creates it:
#   d  /var/lib/greetd 0700 greetd greetd -
#
# The two files coexist rather than conflict: tmpfiles.d entries run in lexical
# order, so greetd.conf (`Z`, no-op on a missing path) runs first, then
# greetd-home.conf (`d`) creates it.
#
# Note the vendor file deliberately passes `-` for Mode - see its own comment
# about dynamic users/groups not being stable across builds. We assert 0700
# explicitly instead. If greetd upstream ever changes the permissions it wants,
# ours will silently win; drop to `-` in the Mode column if that becomes a
# problem and let `Z` handle it.
install -d -m 0755 /usr/lib/tmpfiles.d /etc/greetd /etc/nix /etc/niri
install -m 0644 /tmp/vertos-config/greetd/greetd-home.conf /usr/lib/tmpfiles.d/greetd-home.conf
install -m 0644 /tmp/vertos-config/greetd/config.toml /etc/greetd/config.toml
install -m 0644 /tmp/vertos-config/niri/config.kdl /etc/niri/config.kdl
install -m 0644 /tmp/vertos-config/nix/nix.conf /etc/nix/nix.conf
install -m 0644 /tmp/vertos-config/systemd/nix-store-root.service \
  /usr/lib/systemd/system/nix-store-root.service
install -m 0644 /tmp/vertos-config/systemd/nix.mount \
  /usr/lib/systemd/system/nix.mount
install -m 0644 /tmp/vertos-assets/vertos-fastfetch.png \
  /usr/share/fastfetch/os-logo.png
install -m 0644 /tmp/vertos-assets/vertos-plymouth.png \
  /usr/share/plymouth/themes/spinner/watermark.png
# Firewall zone + LLMNR/mDNS off — in /usr/lib so /etc stays free for local overrides
install -D -m 0644 /tmp/vertos-config/firewalld/vertos.xml /usr/lib/firewalld/zones/vertos.xml
install -D -m 0644 /tmp/vertos-config/resolved/50-no-llmnr.conf \
  /usr/lib/systemd/resolved.conf.d/50-no-llmnr.conf
rm -rf /tmp/vertos-config /tmp/vertos-assets
