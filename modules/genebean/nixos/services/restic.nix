{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.restic;
  # Reuses the same cache the module-generated restic-backups-daily.service
  # already maintains at /var/cache/restic-backups-daily (its own
  # CacheDirectory), rather than each raw unit below getting no cache at
  # all - confirmed on nixnuc: without RESTIC_CACHE_DIR, restic falls back
  # to "unable to locate cache directory: neither $XDG_CACHE_HOME nor
  # $HOME are defined" and warns "running prune without a cache, this may
  # be very slow!" - restic-fleet-prune was still stuck on the read-only
  # scan phase 5+ hours in when this was caught. Each unit below also
  # declares its own CacheDirectory (same name) rather than relying on
  # restic-backups-daily.service having already run first to create it -
  # CacheDirectory is idempotent, so multiple units declaring the same one
  # just share it safely.
  resticEnv = {
    RESTIC_REPOSITORY_FILE = config.sops.secrets.restic_repo.path;
    RESTIC_PASSWORD_FILE = config.sops.secrets.restic_password.path;
    RESTIC_CACHE_DIR = "/var/cache/restic-backups-daily";
  };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.restic ];

    sops.secrets = {
      restic_env.sopsFile = ../../../shared/secrets.yaml;
      restic_repo.sopsFile = ../../../shared/secrets.yaml;
      restic_password.sopsFile = ../../../shared/secrets.yaml;
    };

    services.restic.backups.daily = {
      initialize = true;
      environmentFile = config.sops.secrets.restic_env.path;
      repositoryFile = config.sops.secrets.restic_repo.path;
      passwordFile = config.sops.secrets.restic_password.path;
      extraBackupArgs = [ "--retry-lock 2h" ];
      # Deliberately no pruneOpts - the module always bundles that into
      # `forget --prune`, and prune is a whole-repo operation. See
      # restic-forget-daily below for the cheap, host-scoped replacement.
    };

    systemd.services = {
      restic-forget-daily = {
        description = "Forget old restic snapshots for this host only (cheap - no prune)";
        after = [ "restic-backups-daily.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = config.sops.secrets.restic_env.path;
          CacheDirectory = "restic-backups-daily";
          CacheDirectoryMode = "0700";
        };
        environment = resticEnv;
        script = ''
          ${lib.getExe pkgs.restic} forget \
            --host ${config.networking.hostName} \
            --keep-daily 7 --keep-weekly 5 --keep-monthly 6 --keep-tag pre-reinstall
        '';
        startAt = "daily";
      };

      # Deliberately host-UNscoped: this is the fleet-wide safety net
      # for pre-reinstall tags, including from a host that's since been
      # fully decommissioned and can no longer run its own forget.
      restic-forget-pre-reinstall-backstop = {
        description = "Fleet-wide backstop: expire any pre-reinstall-tagged snapshot older than 1y, any host (cheap - no prune)";
        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = config.sops.secrets.restic_env.path;
          CacheDirectory = "restic-backups-daily";
          CacheDirectoryMode = "0700";
        };
        environment = resticEnv;
        script = ''
          ${lib.getExe pkgs.restic} forget --tag pre-reinstall --keep-within 1y
        '';
        startAt = "daily";
      };
    }
    // lib.optionalAttrs cfg.enablePruneJob {
      restic-fleet-prune = {
        description = "Reclaim space for the whole shared restic repo (all hosts' data) - the one place this runs fleet-wide";
        after = [ "restic-forget-daily.service" ]; # best-effort ordering only - prune is always safe regardless of timing, this just makes it more effective
        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = config.sops.secrets.restic_env.path;
          CacheDirectory = "restic-backups-daily";
          CacheDirectoryMode = "0700";
        };
        environment = resticEnv;
        script = "${lib.getExe pkgs.restic} prune";
        startAt = "04:00"; # later than every host's own daily/forget schedule
      };
    };
  };
}
