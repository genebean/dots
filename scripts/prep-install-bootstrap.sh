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
# No RTC on these Pis, so without a persisted clock file, systemd-
# timesyncd has no floor and every boot starts from whatever fallback the
# kernel/image build defaults to until NTP catches up moments later - a
# real window where cert/timestamp validation could see the wrong time,
# not just cosmetic log confusion. mightymac's own clock is already
# NTP-correct, so touching this file here (content doesn't matter, only
# its mtime) gives the very first boot a reasonable floor immediately,
# before that boot's own NTP sync has had a chance to run. Persistence.nix
# then keeps that floor accurate on every subsequent boot - see the
# comment there. Harmless if the target host doesn't persist this path.
timesync_clock_path="${out_dir}/persist/var/lib/systemd/timesync/clock"

ssh_key_tmp="$(mktemp)"
restic_env_tmp="$(mktemp)"
trap 'rm -f "$ssh_key_tmp" "$restic_env_tmp"' EXIT

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

mkdir -p "$(dirname "$timesync_clock_path")"
touch "$timesync_clock_path"

recipient="$(nix shell nixpkgs#age --command age-keygen -y "$age_key_path")"
echo "Derived age recipient: ${recipient}"
echo "(confirm this matches ${hostname}'s recipient in .sops.yaml before installing)"

# Best-effort: tag this host's last 5 restic snapshots as pre-reinstall
# before the reinstall wipes it, so kiosk-restic-full-restore has known-
# good state to fall back on even if a boot-triggered catch-up backup on
# the fresh install captures empty state first and would otherwise get
# treated as "latest". Talks to the repo directly rather than over SSH to
# the device being reinstalled - mightymac is already a valid recipient
# for these same restic secrets in modules/shared/secrets.yaml, and this
# way it still works even if the device's own SSH/network is flaky right
# before a reinstall. See modules/shared/nixos/restic.nix and
# kiosk-gene-desk/persistence.nix for the retention side of this.
sops decrypt --extract '["restic_env"]' "${repo_root}/modules/shared/secrets.yaml" > "$restic_env_tmp"
set -a
# shellcheck disable=SC1090
source "$restic_env_tmp"
set +a
export RESTIC_REPOSITORY
RESTIC_REPOSITORY="$(sops decrypt --extract '["restic_repo"]' "${repo_root}/modules/shared/secrets.yaml")"
export RESTIC_PASSWORD
RESTIC_PASSWORD="$(sops decrypt --extract '["restic_password"]' "${repo_root}/modules/shared/secrets.yaml")"

echo "Tagging ${hostname}'s last 5 restic snapshots as pre-reinstall..."
snapshot_ids="$(nix run nixpkgs#restic -- snapshots --host "${hostname}" --latest 5 --json | nix run nixpkgs#jq -- -r '.[].short_id')"
if [ -n "$snapshot_ids" ]; then
  # shellcheck disable=SC2086
  nix run nixpkgs#restic -- tag --add pre-reinstall $snapshot_ids
  echo "Tagged: $(echo "$snapshot_ids" | tr '\n' ' ')"
else
  echo "No existing snapshots found for ${hostname} - nothing to tag."
fi

echo ""
echo "Ready. Run:"
echo "  nixos-anywhere --flake ${repo_root}#${hostname} --extra-files ${out_dir} root@<pi-ip>"
