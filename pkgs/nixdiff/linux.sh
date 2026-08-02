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

  # Systemd unit diff — system-manager manages units via a source directory, not text,
  # so they are not captured by the text-file loop above.
  sm_systemd_source=$(jq -r '.entries["systemd/system"].source // empty' "$sm_etc")
  if [[ -n "$sm_systemd_source" ]]; then
    echo ""
    echo "=== System-manager systemd unit changes ==="
    new_units=$(readlink -f "$sm_systemd_source/systemd/system")

    sm_profile="/nix/var/nix/profiles/system-manager-profiles/system-manager"
    if [[ -L "$sm_profile" ]]; then
      old_etc=$(readlink -f "$sm_profile")/etcFiles/etcFiles.json
      old_source=$(jq -r '.entries["systemd/system"].source // empty' "$old_etc" 2>/dev/null)
      old_units=$(readlink -f "$old_source/systemd/system" 2>/dev/null || echo "")
    else
      old_units=""
    fi

    # List only unit files (symlinks/files), not .wants/.requires dirs
    list_units() {
      local f
      for f in "$1"/*; do
        [[ -e "$f" ]] || continue
        [[ -d "$f" ]] && continue
        printf '%s\n' "${f##*/}"
      done | sort
    }

    if [[ -z "$old_units" || ! -d "$old_units" ]]; then
      echo "(no previous profile — all units are new)"
      list_units "$new_units" | while IFS= read -r unit; do
        echo "  + $unit"
      done
    else
      any_unit_change=false

      while IFS= read -r unit; do
        [[ -n "$unit" ]] && echo "  + $unit" && any_unit_change=true
      done < <(comm -13 <(list_units "$old_units") <(list_units "$new_units"))

      while IFS= read -r unit; do
        [[ -n "$unit" ]] && echo "  - $unit" && any_unit_change=true
      done < <(comm -23 <(list_units "$old_units") <(list_units "$new_units"))

      while IFS= read -r unit; do
        old_file=$(readlink -f "$old_units/$unit" 2>/dev/null || echo "")
        new_file=$(readlink -f "$new_units/$unit" 2>/dev/null || echo "")
        if [[ -f "$old_file" && -f "$new_file" ]]; then
          if ! diff -q "$old_file" "$new_file" &>/dev/null; then
            diff -u "$old_file" "$new_file" \
              --label "$unit (current)" --label "$unit (new)" \
              | diff-so-fancy || true
            any_unit_change=true
          fi
        fi
      done < <(comm -12 <(list_units "$old_units") <(list_units "$new_units"))

      if [[ "$any_unit_change" != "true" ]]; then
        echo "(no changes)"
      fi
    fi
  fi

  home-manager build --flake ".#$(whoami)-$(uname -m)-linux"

  echo ""
  echo "=== Package changes ==="
  nvd diff "${HOME}/.local/state/nix/profiles/home-manager" result
fi
