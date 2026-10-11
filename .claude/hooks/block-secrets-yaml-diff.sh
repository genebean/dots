#!/usr/bin/env bash
# PreToolUse/Bash guard: hard-block any git diff/show/log invocation that
# could render secrets.yaml content. dots has a textconv configured for
# sops-managed YAML (git diff/show on it renders fully decrypted
# plaintext) - not a leak on disk, but there's no reason to ever pull a
# secret's real value into a session's context.
#
# Deliberately does NOT just re-run the command with --name-only to see
# what it would touch - that would execute any embedded command
# substitution (e.g. `git diff $(...)`) as a side effect purely to decide
# whether to allow it, which is a worse problem than the one being solved.
# Pure text inspection instead, failing closed: a diff/show/log segment is
# only allowed through if it's EITHER already a content-free format
# (--stat/--name-only/--name-status) OR has at least one explicit,
# non-secrets.yaml path argument scoping it. A bare `git diff`/
# `git diff <ref>`/`git show <ref>`/`git log -p` with no path at all could
# touch anything, including secrets.yaml, so it's denied rather than
# assumed safe.
#
# Segments are split on &&/||/;/| so one git invocation's --stat/path
# argument can't wrongly exempt a different, unscoped git invocation later
# in the same chain. Residual risk: this is still text-based command
# inspection, not a real shell parser - subshells, command substitution,
# or an alias/function named `git` are not defused.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

segments=$(echo "$cmd" | sed -E 's/(&&|\|\||[;|])/\n/g')

deny() {
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}

while IFS= read -r segment; do
  [ -n "$segment" ] || continue

  echo "$segment" | grep -Eq -- 'git\s+(diff|show|log)\b' || continue

  # Already content-free - safe regardless of what it touches.
  if echo "$segment" | grep -Eq -- '(--stat\b|--name-only\b|--name-status\b)'; then
    continue
  fi

  # Explicitly mentions a secrets.yaml path - unsafe, full stop.
  if echo "$segment" | grep -qiE -- 'secrets\.ya?ml'; then
    deny "git diff/show/log on a secrets.yaml file is blocked outright - dots'\''s sops textconv renders full decrypted plaintext into this session'\''s context for no reason. Use grep/cat for an existence or key-name check, or git diff --stat/--name-only if you just need to know a secrets file changed."
  fi

  # Has at least one other path-like argument (contains / or a dotted
  # extension) scoping it away from secrets.yaml - provably safe, git only
  # shows diffs for paths matching a given pathspec.
  if echo "$segment" | grep -qE -- '(/|\.[a-zA-Z0-9]+)\S*( |$)'; then
    continue
  fi

  # No content-free flag, no secrets.yaml mention, no other path argument
  # either - this is unscoped (bare `git diff`, a ref-only `git show
  # <sha>`, `git log -p`, etc.) and could touch anything, including
  # secrets.yaml. Fail closed rather than assume it's safe.
  deny "Unscoped git diff/show/log (no path argument) could render secrets.yaml content if it'\''s part of the diff - denied rather than assumed safe. Add an explicit path, or use --stat/--name-only first to check what'\''s included."
done <<< "$segments"

exit 0
