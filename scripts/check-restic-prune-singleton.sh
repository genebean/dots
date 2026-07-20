#!/usr/bin/env bash
# restic prune is a whole-repository operation (see
# modules/genebean/nixos/services/restic.nix) - it must run on exactly one
# host across the fleet, or space is either never reclaimed (zero hosts) or
# reclaimed redundantly (more than one). This is a fast text check, not a
# full `nix eval` of every host's resolved config - it can be fooled by a
# stray comment or duplicate line, but catches the common mistake cheaply
# on every commit.
set -euo pipefail

matches=$(grep -rl 'enablePruneJob = true' modules/hosts/ || true)
count=$(printf '%s' "$matches" | grep -c . || true)

if [ "$count" -ne 1 ]; then
  echo "error: expected exactly one host with genebean.services.restic.enablePruneJob = true, found $count" >&2
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches" >&2
  fi
  exit 1
fi
