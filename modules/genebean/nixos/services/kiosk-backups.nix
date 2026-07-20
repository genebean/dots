{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.kiosk-backups;
  resticCfg = config.home-manager.users.${username}.genebean.services.restic;
  usesImpermanence = config.environment.persistence."/persist".enable or false;
  prefixedPaths = map (path: if usesImpermanence then "/persist${path}" else path) cfg.paths;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(lib.any (lib.hasPrefix "/persist") cfg.paths);
        message = "genebean.services.kiosk-backups.paths must not include a /persist prefix - it's added automatically when the host uses impermanence.";
      }
      {
        assertion = resticCfg.enable;
        message = "genebean.services.kiosk-backups requires genebean.services.restic.enable = true - it depends on that module's restic_env/restic_repo/restic_password secrets and base daily backup job.";
      }
    ];

    services.restic.backups.daily = {
      paths = prefixedPaths;
      # Avoid a boot-triggered catch-up backup capturing the wrong state
      # as "latest" before a chance to restore after a reinstall -
      # confirmed on kiosk-gene-desk hardware, see its original comment.
      timerConfig = {
        OnCalendar = "daily";
        Persistent = false;
      };
    };

    systemd.services.restic-forget-kiosk-pre-reinstall = {
      description = "Expire this kiosk's own pre-reinstall-tagged snapshots older than 45d (cheap - no prune)";
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.secrets.restic_env.path;
        # Reuses genebean.services.restic's own cache dir (same repo) -
        # see that module's resticEnv comment for why this matters.
        CacheDirectory = "restic-backups-daily";
        CacheDirectoryMode = "0700";
      };
      environment = {
        RESTIC_REPOSITORY_FILE = config.sops.secrets.restic_repo.path;
        RESTIC_PASSWORD_FILE = config.sops.secrets.restic_password.path;
        RESTIC_CACHE_DIR = "/var/cache/restic-backups-daily";
      };
      script = ''
        ${lib.getExe pkgs.restic} forget \
          --tag pre-reinstall --host ${config.networking.hostName} --keep-within 45d
      '';
      startAt = "daily";
    };

    genebean.programs.kiosk-restic-full-restore = {
      enable = true;
      restorePaths = prefixedPaths;
      stopServices = [
        "cage-tty1"
        "tailscaled"
      ];
    };
  };
}
