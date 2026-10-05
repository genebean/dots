#!/usr/bin/env bash
# A bare "#NNN" in a commit message autolinks on GitHub to an issue/PR in
# whichever repo hosts the commit - wrong whenever the reference is actually
# to another repo (e.g. the hermes-agent-fleet-plan planning repo on
# Forgejo). Require an explicit repo prefix ("dots#40",
# "hermes-agent-fleet-plan#40", or spelled out as "hermes-agent-fleet-plan
# issue 40") so the reference (or deliberate absence of a link) is never
# accidental. pre-commit passes the commit-message file path as $1 at the
# commit-msg stage.
set -euo pipefail

msg_file="$1"

if grep -nP '(?<![A-Za-z0-9_-])#[0-9]+' "$msg_file"; then
  echo >&2
  echo "error: bare '#NNN' issue/PR reference found above." >&2
  echo "This autolinks to THIS repo's own tracker on GitHub, which is wrong" >&2
  echo "for a cross-repo reference. Spell it out unambiguously instead:" >&2
  echo "  dots#40                        (this repo)" >&2
  echo "  hermes-agent-fleet-plan#40     (another repo, same owner)" >&2
  echo "  hermes-agent-fleet-plan issue 40  (a non-GitHub tracker, e.g. Forgejo)" >&2
  exit 1
fi
