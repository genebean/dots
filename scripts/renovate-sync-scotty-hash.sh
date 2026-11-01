#!/usr/bin/env bash
# Run by .github/workflows/renovate-sync.yml for bead-me-up-scotty.nix's scottyRev
# customManager. Unlike a flake input, scottyRev feeds a plain fetchFromGitHub
# with its own sha256 pinned alongside it (modules/hosts/nixos/nixnuc/
# containers/bead-me-up-scotty.nix) - a regex-only version bump leaves that
# hash stale, which is worse than a silent drift: the build hard-fails on
# the next deploy because the fetched source no longer matches the pinned
# fixed-output-derivation hash. Usage: pass the new scottyRev tag, e.g.
# `renovate-sync-scotty-hash.sh v0.3.3`. Verified against the currently
# pinned v0.3.2 (sha256-hXzGUr7Qhdkj6AqO9WW7Pi93b71Kc2GdYaxBB4cUfVs=,
# matches the base32 value already in the file, and the resulting nixnuc
# system derivation evaluates cleanly) before this script was ever wired
# into Renovate config.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <scotty-rev>" >&2
  exit 2
fi

rev="$1"
file="modules/hosts/nixos/nixnuc/containers/bead-me-up-scotty.nix"

new_hash=$(nix run nixpkgs#nix-prefetch-github -- brendan-appstart bead-me-up-scotty --rev "$rev" | jq -r '.hash')

if [ -z "$new_hash" ] || [ "$new_hash" = "null" ]; then
  echo "error: nix-prefetch-github produced no hash for rev $rev" >&2
  exit 1
fi

sed -i "s|sha256 = \"[^\"]*\";|sha256 = \"${new_hash}\";|" "$file"
