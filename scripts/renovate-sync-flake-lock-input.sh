#!/usr/bin/env bash
# Renovate postUpgradeTask companion for any customManager that bumps a flake
# input's version/ref directly in flake.nix via regex (not Renovate's
# built-in nix manager - that one re-locks automatically via its own
# lockFileMaintenance delegation to `nix`). A regex manager only edits the
# matched string; it has no concept of flake.lock, so without this, every
# such bump silently leaves flake.lock pointing at the old commit until
# something else (a manual `nix flake update`, or a deploy tool's own
# evaluation) catches it up. Usage: pass the flake input's attribute name
# (the left side of `<name>.url = ...` in flake.nix), e.g.
# `renovate-sync-flake-lock-input.sh hermes-agent` - not the Renovate
# depName, which may differ (e.g. "NousResearch/hermes-agent").
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <flake-input-name>" >&2
  exit 2
fi

nix flake lock --update-input "$1"
