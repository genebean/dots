#!/usr/bin/env bash
# Prepares the nixos-anywhere --extra-files directory needed to bootstrap
# sops on a fresh install: disko wipes /persist from scratch every time,
# so the sops age key has to be re-seeded before activation runs, or
# sops-install-secrets fails on first boot with no way to recover it
# short of a manual SSH patch.
#
# Expects a per-host SSH private key named ssh_private_key_gene_<hostname>
# in modules/shared/secrets.yaml (decryptable by every host/user in the
# fleet, per .sops.yaml), matching the *_authorized_keys entry already
# declared in private-flake's ssh-keys lib for that host. The age key is
# deterministically derived from it via ssh-to-age, so it always
# reproduces the same identity already registered as a recipient in
# .sops.yaml for that host - nothing needs to be re-encrypted.
#
# Usage: scripts/prep-install-bootstrap.sh <hostname>
# Then:  nixos-anywhere --flake ~/repos/dots#<hostname> \
#          --extra-files ./nixos-anywhere-extras-<hostname> root@<ip>
set -euo pipefail

hostname="${1:?usage: $0 <hostname>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
secret_name="ssh_private_key_gene_${hostname}"
out_dir="${repo_root}/nixos-anywhere-extras-${hostname}"
# Flat path, not nested under .config: this file gets copied onto the
# target as root before nixos-install's activation ever runs, which
# would create .config itself as root:root as a side effect and (on
# kiosk-gene-desk at least) permanently break anything impermanence
# later needs to bind-mount under .config - systemd-tmpfiles refuses to
# fix it after the fact ("Detected unsafe path transition"). See the
# comment on sops.age.keyFile in kiosk-gene-desk/default.nix.
age_key_path="${out_dir}/persist/home/gene/.sops-age-key"

ssh_key_tmp="$(mktemp)"
trap 'rm -f "$ssh_key_tmp"' EXIT

# Wiped fresh, not just mkdir -p'd: out_dir persists between runs, so a
# stale file from a previous run's now-changed layout would otherwise
# silently tag along into --extra-files on a later run and get copied
# onto the target.
rm -rf "$out_dir"

echo "Decrypting ${secret_name} from modules/shared/secrets.yaml..."
sops decrypt --extract "[\"${secret_name}\"]" "${repo_root}/modules/shared/secrets.yaml" > "$ssh_key_tmp"
chmod 600 "$ssh_key_tmp"

mkdir -p "$(dirname "$age_key_path")"
nix run nixpkgs#ssh-to-age -- -private-key -i "$ssh_key_tmp" > "$age_key_path"
chmod 600 "$age_key_path"

recipient="$(nix shell nixpkgs#age --command age-keygen -y "$age_key_path")"
echo "Derived age recipient: ${recipient}"
echo "(confirm this matches ${hostname}'s recipient in .sops.yaml before installing)"

echo ""
echo "Ready. Run:"
echo "  nixos-anywhere --flake ${repo_root}#${hostname} --extra-files ${out_dir} root@<pi-ip>"
