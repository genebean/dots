#!/usr/bin/env bash
# Retries every failed operation (retain/reflect/etc) on a Hindsight bank.
# Failures cluster around LLM backend issues - a quota-exhausted subscription,
# or (before the CPU/timeout fixes in ollama.nix and
# containers/hindsight-gene-personal.nix) a local Ollama request that took
# longer than the provider timeout - and Hindsight doesn't retry those on its
# own, so this exists to requeue them in bulk once the underlying cause is
# fixed.
#
# Usage: scripts/hindsight-retry-failed.sh <bank_id> [api_url]
#   scripts/hindsight-retry-failed.sh coding-agent::dots
#   scripts/hindsight-retry-failed.sh gene-personal http://nixnuc:8889
set -euo pipefail

bank_id="${1:?usage: $0 <bank_id> [api_url]}"
api_url="${2:-http://nixnuc:8889}"

ops_json=$(curl -sf "${api_url}/v1/default/banks/${bank_id}/operations?status=failed&limit=100")

ids=$(printf '%s' "$ops_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for op in d.get('operations', []):
    print(op['id'])
")

if [ -z "$ids" ]; then
  echo "No failed operations on bank '${bank_id}'."
  exit 0
fi

count=$(printf '%s\n' "$ids" | grep -c .)
echo "Retrying ${count} failed operation(s) on bank '${bank_id}'..."

ok=0
failed=0
while IFS= read -r id; do
  [ -z "$id" ] && continue
  if curl -sf -X POST "${api_url}/v1/default/banks/${bank_id}/operations/${id}/retry" >/dev/null; then
    echo "  retried: ${id}"
    ok=$((ok + 1))
  else
    echo "  FAILED to retry: ${id}" >&2
    failed=$((failed + 1))
  fi
done <<<"$ids"

echo "Done: ${ok} retried, ${failed} failed to queue."
