#!/usr/bin/bash

set -euxo pipefail

# GPU vendor comes in as $1 from the Containerfile RUN line.
# Fail loudly rather than silently building the wrong variant.
GPU_VENDOR="${1:?GPU_VENDOR not passed - expected 'amd' or 'nvidia'}"

case "${GPU_VENDOR}" in
amd | nvidia) ;;
*)
  echo "ERROR: unknown GPU_VENDOR '${GPU_VENDOR}'" >&2
  exit 1
  ;;
esac

# Bazzite ships /opt as a symlink into /var/opt (the older FCOS-style
# pattern). That caused two separate problems: a build-time cpio error when
# installing RPMs that target /opt (Brave, Mullvad, etc.), and - more
# seriously - content written there gets silently DISCARDED on real
# deployments, because ostree treats /var like a Docker volume: it's only
# populated from the image when the machine's stateroot /var is still
# empty, and once it isn't, existing files are never overwritten by a
# newer image. That's why Brave installed cleanly at build time but ended
# up with nothing in /opt after actually switching to the image.
#
# Fix (bootc's own documented approach for base images that want /opt
# content to "just work" from a derived build): make /opt a real directory
# instead of a symlink, so anything installed there becomes part of the
# immutable, properly-versioned root filesystem - same as /usr - rather
# than machine-local persistent state.
rm -f /opt && mkdir -p /opt

# Third party repos
curl -fsSLo /etc/yum.repos.d/brave-browser.repo \
  https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
curl -fsSLo /etc/yum.repos.d/mullvad.repo \
  https://repository.mullvad.net/rpm/stable/mullvad.repo

# Not sure about these yet...
# dnf5 -y remove fw-fanctrl
# dnf5 -y remove xwaylandvideobridge
# orca is GNOME orca - screen reader

REMOVE_PKGS=(
  lutris
  nautilus
  waydroid
  waydroid-selinux
  gnome-shell
  gnome-shell-common
  gnome-session
  gnome-session-wayland-session
  gnome-settings-daemon
  gnome-control-center
  gnome-remote-desktop
  gnome-shell-extension-common
  gnome-shell-extension-gsconnect
  gnome-shell-extension-user-theme
  steamdeck-gnome-presets
  gnome-browser-connector
  gnome-user-share
  gnome-user-docs
  gnome-online-accounts
  gnome-bluetooth
  gnome-color-manager
  gnome-epub-thumbnailer
  gnome-srpm-macros
  f44-backgrounds-gnome
  desktop-backgrounds-gnome
  gnome-backgrounds
  fedora-chromium-config-gnome
  NetworkManager-ssh-gnome
  NetworkManager-openconnect-gnome
  NetworkManager-vpnc-gnome
  NetworkManager-openvpn-gnome
  orca
)
dnf5 remove -y --no-autoremove "${REMOVE_PKGS[@]}"

INSTALL_PKGS=(
  alacritty
  brave-browser
  clamav
  clamav-freshclam
  fuzzel
  fish
  gh
  greetd
  kitty
  libayatana-appindicator-gtk3
  mullvad-vpn
  niri
  nix
  nix-daemon
  nix-legacy
  noctalia
  nvtop
  pam-u2f
  pamu2fcfg
  pcsc-lite
  pcsc-tools
  podman-compose
  strace
  thunar
  tuigreet
  yubikey-manager
)

# AMD-only diagnostics; nvtop above already covers NVIDIA.
if [ "${GPU_VENDOR}" = "amd" ]; then
  INSTALL_PKGS+=(radeontop rocminfo rocm-smi)
fi

dnf5 install -y "${INSTALL_PKGS[@]}"

# Clean dnf5 cache — needed since we no longer use --mount=type=cache
# (rootless buildah cache mounts currently broken on GH Actions runners)
dnf5 clean all
