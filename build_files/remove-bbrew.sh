#!/usr/bin/bash
#
# PARKED - not currently wired into the Containerfile.
#
# Removes ublue's bbrew (Homebrew helper) and masks the brew systemd units.
# Re-add with:
#
#   COPY build_files/remove-bbrew.sh /tmp/remove-bbrew.sh
#   RUN /tmp/remove-bbrew.sh && rm -f /tmp/remove-bbrew.sh
#
# bbrew is NOT rpm-managed - `rpm -qa | grep -i brew` returns nothing but
# Hebrew fonts (the substring matches "he-brew") - so it cannot be removed with
# dnf5 and has to be deleted by path.
#
# The paths below were verified against the base image by running:
#   find / -xdev \( -iname '*bbrew*' -o -iname '*bold-brew*' \
#       -o -iname '*bold_brew*' \) -not -path '/proc/*' -not -path '/sys/*' -print
#
# Re-verify after a base image bump. If ublue renames or adds files, the
# explicit list below will silently miss them - see the alternative at the
# bottom of this file if you would rather sweep than enumerate.

set -euo pipefail

systemctl mask \
    brew-setup.service \
    brew-update.timer \
    brew-upgrade.timer

rm -f \
    /usr/bin/bbrew-helper \
    /usr/share/applications/bbrew.desktop \
    /usr/share/ublue-os/bbrew.png \
    /usr/share/ublue-os/docs/html/img/bbrew-installed-screenshot.png

# Alternative, future-proof against renames but deletes whatever it matches -
# re-check its output before trusting it after a base bump:
#
# find / -xdev \( -iname '*bbrew*' -o -iname '*bold-brew*' -o -iname '*bold_brew*' \) \
#     -not -path '/proc/*' -not -path '/sys/*' -delete
