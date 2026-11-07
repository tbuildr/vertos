#!/usr/bin/bash

set -euxo pipefail

# Verify vertos container images using this repository's Cosign key.
#
# The policy edit preserves Bazzite's existing policy and adds verification for
# vertos. Repo-wide, so both variants (tagged amd-* / nvidia-* in the same repo)
# are covered by matchRepository without touching this block per variant.
#
install -d -m 0755 /etc/pki/containers /etc/containers/registries.d
install -m 0644 /tmp/vertos.pub /etc/pki/containers/vertos.pub
rm -f /tmp/vertos.pub
policy_tmp="$(mktemp)"
jq '.transports //= {} | .transports.docker //= {} | .transports.docker["ghcr.io/tbuildr/vertos"] = [{"type":"sigstoreSigned","keyPath":"/etc/pki/containers/vertos.pub","signedIdentity":{"type":"matchRepository"}}]' \
  /etc/containers/policy.json >"${policy_tmp}"

jq empty "${policy_tmp}"
install -m 0644 "${policy_tmp}" /etc/containers/policy.json
rm -f "${policy_tmp}"
printf '%s\n' \
  'docker:' \
  '  ghcr.io/tbuildr/vertos:' \
  '    use-sigstore-attachments: true' \
  >/etc/containers/registries.d/vertos.yaml

rm -rf /tmp/vertos-build_files
