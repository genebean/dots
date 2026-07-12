{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "nixdiff";
      runtimeInputs = [
        pkgs.jq
        pkgs.nvd
      ];
      text = ''
        cd ~/repos/dots

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
        hm_svc="result/etc/systemd/system/home-manager-''${USER}.service"
        hm_old="''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/flatpak-state.json"
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
      '';
    })
  ];

  programs = {
    # Linux-specific aliases
    zsh.shellAliases = {
      nixboot = "sudo nixos-rebuild boot --flake ~/repos/dots && echo 'Time to reboot!'";
      nixup = "sudo nixos-rebuild switch --flake ~/repos/dots";
      uwgconnect = "nmcli dev wifi connect SecureWest password";
      uwgforget = "nmcli connection delete SecureWest";
      ykey = "sudo systemctl restart pcscd && sudo pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L";
    };
  };
}
