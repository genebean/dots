# Disaster-recovery tool for kiosks running cage+chromium(+tailscale): pulls
# hass-browser_mod's chromium state, atuin's login, and similar back from
# restic after a card death or fresh reinstall. Not for servers - the
# services.restic.backups.<name> module already covers those on its own.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.genebean.programs.kiosk-restic-full-restore;
in
{
  options.genebean.programs.kiosk-restic-full-restore = {
    enable = lib.mkEnableOption "kiosk-restic-full-restore recovery tool";

    backupName = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Name of the services.restic.backups.<name> job to restore from.";
    };

    restorePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Paths to restore from the chosen snapshot (normally the same list passed to services.restic.backups.<name>.paths).";
      example = [ "/persist/home/gene/.config/chromium" ];
    };

    stopServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "systemd services to stop before restoring and start again afterward, e.g. the kiosk browser session and tailscaled - anything that holds the restored files open.";
      example = [
        "cage-tty1"
        "tailscaled"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "kiosk-restic-full-restore";
        text = ''
          if [ $# -eq 0 ]; then
            # No snapshot chosen yet - show what's available and stop. Doesn't
            # default to "latest": confirmed on hardware that a boot-triggered
            # catch-up backup capturing empty post-reinstall state can become
            # "latest" before there's a chance to restore, silently making
            # "latest" the wrong snapshot to restore from.
            restic-${cfg.backupName} snapshots --host "$(hostname)"
            echo
            echo "Usage: kiosk-restic-full-restore <snapshot-id>"
            exit 0
          fi
          snapshot="$1"

          echo "Restoring snapshot '$snapshot' (host: $(hostname)) for:"
          ${lib.concatMapStringsSep "\n" (p: "echo '  ${p}'") cfg.restorePaths}
          echo
          read -r -p "This overwrites the current state at these paths. Continue? [y/N] " confirm
          [ "$confirm" = "y" ] || exit 1

          ${lib.optionalString (
            cfg.stopServices != [ ]
          ) "systemctl stop ${lib.concatStringsSep " " cfg.stopServices}"}

          # atuin isn't a service - each shell command spawns a short-lived
          # `atuin history end` process to record it. One of these caught mid-
          # write during a live restore held its old (now-deleted) sqlite file
          # open, and new `atuin` invocations hung with "pool timed out
          # waiting for an open connection" until it was killed. Harmless to
          # kill - it's just finishing writing one command's exit status.
          pkill -u ${username} -x atuin || true

          restic-${cfg.backupName} restore "$snapshot" --host "$(hostname)" --target / \
            ${lib.concatMapStringsSep " " (p: "--include ${lib.escapeShellArg p}") cfg.restorePaths}

          ${lib.optionalString (
            cfg.stopServices != [ ]
          ) "systemctl start ${lib.concatStringsSep " " cfg.stopServices}"}
          echo "Restored${
            lib.optionalString (
              cfg.stopServices != [ ]
            ) " and restarted ${lib.concatStringsSep " + " cfg.stopServices}"
          }."
        '';
      })
    ];
  };
}
