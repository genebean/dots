cd ~/repos/dots

# shellcheck source=/dev/null
source /etc/os-release

if [[ "${ID:-}" == "nixos" ]]; then
  nixos-rebuild build --flake .

  echo ""
  echo "=== Package changes ==="
  nvd diff /run/current-system result

  _flatpak_diff() {
    local old="$1" new="$2"
    local removed="" added=""
    if [[ -f "$old" ]]; then
      removed=$(comm -23 \
        <(jq -r '.packages[].appId' "$old" | sort) \
        <(jq -r '.packages[].appId' "$new" | sort))
      added=$(comm -13 \
        <(jq -r '.packages[].appId' "$old" | sort) \
        <(jq -r '.packages[].appId' "$new" | sort))
    else
      added=$(jq -r '.packages[].appId' "$new" | sort)
    fi
    if [[ -z "$removed" && -z "$added" ]]; then
      echo "(no changes)"
    else
      while IFS= read -r app; do
        if [[ -n "$app" ]]; then echo "  - $app"; fi
      done <<< "$removed"
      while IFS= read -r app; do
        if [[ -n "$app" ]]; then echo "  + $app"; fi
      done <<< "$added"
    fi
  }

  # System-level flatpak diff
  sys_svc="result/etc/systemd/system/flatpak-managed-install.service"
  sys_old="/nix/var/nix/gcroots/flatpak-state.json"
  if [[ -f "$sys_svc" ]]; then
    sys_script=$(grep -oP '(?<=ExecStart=)\S+' "$sys_svc" || true)
    if [[ -n "$sys_script" ]]; then
      sys_new=$(grep -oP '/nix/store/\S+-flatpak-state\.json' "$sys_script" | head -1 || true)
      if [[ -n "$sys_new" ]]; then
        echo ""
        echo "=== System flatpak changes ==="
        _flatpak_diff "$sys_old" "$sys_new"
      fi
    fi
  fi

  # User-level flatpak diff (home-manager)
  hm_svc="result/etc/systemd/system/home-manager-${USER}.service"
  hm_old="${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/flatpak-state.json"
  if [[ -f "$hm_svc" ]]; then
    hm_gen=$(grep -oP '/nix/store/\S+-home-manager-generation' "$hm_svc" || true)
    if [[ -n "$hm_gen" ]]; then
      hm_files=$(readlink -f "$hm_gen/home-files")
      hm_fm_svc="$hm_files/.config/systemd/user/flatpak-managed-install.service"
      if [[ -f "$hm_fm_svc" ]]; then
        hm_script=$(grep -oP '(?<=ExecStart=)\S+' "$hm_fm_svc" || true)
        if [[ -n "$hm_script" ]]; then
          hm_new=$(grep -oP '/nix/store/\S+-flatpak-state\.json' "$hm_script" | head -1 || true)
          if [[ -n "$hm_new" ]]; then
            echo ""
            echo "=== User flatpak changes ==="
            _flatpak_diff "$hm_old" "$hm_new"
          fi
        fi
      fi
    fi
  fi

else
  # Home Manager only

  # system-manager diff — stderr (progress logs) flows to terminal; stdout is the store path
  sm_result=$(nix run ~/repos/dots#system-manager -- build \
    --flake ".#$(whoami)-$(uname -m)-linux")

  echo ""
  echo "=== System /etc changes ==="
  sm_etc="$sm_result/etcFiles/etcFiles.json"
  mapfile -t sm_targets < <(jq -r '.entries | to_entries[] | select(.value.text != null) | .key' "$sm_etc")
  if [[ ${#sm_targets[@]} -eq 0 ]]; then
    echo "(no text-mode /etc files managed)"
  fi
  for target in "${sm_targets[@]}"; do
    new_text=$(jq -r --arg k "$target" '.entries[$k].text' "$sm_etc")
    current_src="/etc/$target"
    [[ -f "$current_src" ]] || current_src="/dev/null"
    if diff -q "$current_src" <(printf '%s' "$new_text") &>/dev/null; then
      echo "/etc/$target: no change"
    else
      diff -u "$current_src" <(printf '%s' "$new_text") \
        --label "/etc/$target" --label "/etc/$target" \
        | diff-so-fancy || true
    fi
  done

  home-manager build --flake ".#$(whoami)-$(uname -m)-linux"

  echo ""
  echo "=== Package changes ==="
  nvd diff "${HOME}/.local/state/nix/profiles/home-manager" result
fi
