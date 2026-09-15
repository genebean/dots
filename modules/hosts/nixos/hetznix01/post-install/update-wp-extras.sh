#!/usr/bin/env bash
# Updates the manually-packaged items in wordpress.nix:
#   - infield theme  (fetched from Automattic/themes on GitHub)
#
# Plugins managed by nixpkgs (wp-fail2ban, webp-converter-for-media, etc.)
# are updated via `nix flake update` — no action needed here.
#
# WordPress core itself is pulled from nixpkgs-unstable; update it with:
#   nix flake update nixpkgs-unstable
#
# Usage: ./update-wp-extras.sh [--check]
#   --check   report available updates but do not modify any files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_NIX="$SCRIPT_DIR/wordpress.nix"
CHECK_ONLY=0
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=1

need() { command -v "$1" &>/dev/null || { echo "error: '$1' not found in PATH" >&2; exit 1; }; }
need curl
need jq
need nix
need python3

changed=0

# Replace exactly one occurrence of old_str with new_str in WP_NIX.
# Uses Python so no regex escaping is needed for the hash characters.
replace_in_file() {
    local old="$1" new="$2"
    python3 - "$WP_NIX" "$old" "$new" <<'EOF'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path).read()
if old not in content:
    print(f"error: could not find {old!r} in {path}", file=sys.stderr)
    sys.exit(1)
open(path, "w").write(content.replace(old, new, 1))
EOF
}

prefetch_hash() {
    local url="$1" unpack="${2:-}"
    local flags="--json --hash-type sha256"
    [[ -n "$unpack" ]] && flags="$flags --unpack"
    # shellcheck disable=SC2086
    nix store prefetch-file $flags "$url" 2>/dev/null | jq -r '.hash'
}

# ── infield theme (Automattic/themes, infield/ subdirectory) ──────────────────
echo "==> infield theme"
current_rev=$(python3 -c "
import re, sys
txt = open('$WP_NIX').read()
m = re.search(r'pname = \"infield\".*?rev = \"([^\"]+)\"', txt, re.DOTALL)
print(m.group(1) if m else '')
")
latest_commit=$(curl -sf \
    "https://api.github.com/repos/Automattic/themes/commits?path=infield&per_page=1" \
    | jq -r '.[0].sha')

if [[ -z "$latest_commit" || "$latest_commit" == "null" ]]; then
    echo "  warning: could not fetch latest commit from GitHub, skipping"
elif [[ "$current_rev" == "$latest_commit" ]]; then
    echo "  already at ${current_rev:0:8}"
else
    echo "  ${current_rev:0:8} -> ${latest_commit:0:8}"
    # Fetch version from style.css in the new commit
    new_theme_ver=$(curl -sf \
        "https://raw.githubusercontent.com/Automattic/themes/$latest_commit/infield/style.css" \
        | grep -oP 'Version:\s*\K[\d.]+' | head -1 || true)
    if [[ $CHECK_ONLY -eq 0 ]]; then
        tarball="https://github.com/Automattic/themes/archive/${latest_commit}.tar.gz"
        new_hash=$(prefetch_hash "$tarball" unpack)
        old_hash=$(python3 -c "
import re, sys
txt = open('$WP_NIX').read()
m = re.search(r'pname = \"infield\".*?fetchFromGitHub.*?hash = \"([^\"]+)\"', txt, re.DOTALL)
print(m.group(1) if m else '')
")
        current_theme_ver=$(python3 -c "
import re, sys
txt = open('$WP_NIX').read()
m = re.search(r'pname = \"infield\".*?version = \"([^\"]+)\"', txt, re.DOTALL)
print(m.group(1) if m else '')
")
        replace_in_file "$current_rev" "$latest_commit"
        replace_in_file "$old_hash" "$new_hash"
        if [[ -n "$new_theme_ver" && "$new_theme_ver" != "$current_theme_ver" ]]; then
            # Only the infield version line — use context to target the right one
            replace_in_file \
                "pname = \"infield\";
    version = \"$current_theme_ver\";" \
                "pname = \"infield\";
    version = \"$new_theme_ver\";"
            echo "  Theme version: $current_theme_ver -> $new_theme_ver"
        fi
        echo "  Updated. New hash: $new_hash"
        changed=1
    else
        [[ -n "$new_theme_ver" ]] && echo "  Theme version available: $new_theme_ver"
    fi
fi

echo ""
if [[ $CHECK_ONLY -eq 1 ]]; then
    echo "Check complete (--check mode, no files modified)."
elif [[ $changed -eq 0 ]]; then
    echo "All items are up to date. No changes made."
else
    echo "wordpress.nix updated. Review with 'git diff', then deploy."
fi
