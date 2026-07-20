{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.kiosk-backups;
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
    ];

    services.restic.backups = {
      daily = {
        paths = prefixedPaths;
        # Avoid a boot-triggered catch-up backup capturing the wrong state
        # as "latest" before a chance to restore after a reinstall -
        # confirmed on kiosk-gene-desk hardware, see its original comment.
        timerConfig = {
          OnCalendar = "daily";
          Persistent = false;
        };
      };

      pre-reinstall-cleanup = {
        environmentFile = config.sops.secrets.restic_env.path;
        passwordFile = config.sops.secrets.restic_password.path;
        repositoryFile = config.sops.secrets.restic_repo.path;
        pruneOpts = [
          "--tag pre-reinstall"
          "--host ${config.networking.hostName}"
          "--keep-within 45d"
        ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = false;
        };
      };
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
