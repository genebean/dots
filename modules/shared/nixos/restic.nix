{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    restic
  ];

  sops.secrets = {
    restic_env.sopsFile = ../secrets.yaml;
    restic_repo.sopsFile = ../secrets.yaml;
    restic_password.sopsFile = ../secrets.yaml;
  };

  services.restic.backups = {
    daily = {
      initialize = true;

      environmentFile = config.sops.secrets.restic_env.path;
      repositoryFile = config.sops.secrets.restic_repo.path;
      passwordFile = config.sops.secrets.restic_password.path;

      extraBackupArgs = [
        "--retry-lock 2h"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 6"
        # Every host shares this one repository and none of these forget
        # invocations are scoped by --host, so any host's prune run
        # processes retention for every host's snapshots, not just its
        # own. This needs to live here (not on whichever host actually
        # uses the tag) so it's honored no matter which host's prune job
        # happens to run first - see kiosk-gene-desk/persistence.nix for
        # where pre-reinstall gets applied.
        "--keep-tag pre-reinstall"
      ];
    };

    # Fleet-wide backstop, deliberately not scoped by --host: whatever
    # per-host cleanup job manages a normal expiry for its own
    # pre-reinstall-tagged snapshots (see kiosk-gene-desk/persistence.nix)
    # is the primary mechanism, but this catches anything that slips
    # through - a host decommissioned before its own cleanup job ran, one
    # disabled/misconfigured, etc. - so pre-reinstall tags can never pin a
    # snapshot forever fleet-wide, only for up to a year.
    pre-reinstall-backstop = {
      environmentFile = config.sops.secrets.restic_env.path;
      repositoryFile = config.sops.secrets.restic_repo.path;
      passwordFile = config.sops.secrets.restic_password.path;
      pruneOpts = [
        "--tag pre-reinstall"
        "--keep-within 1y"
      ];
      # Confirmed on hardware: the module default (Persistent = true) fired
      # this immediately on the same reboot it was first created on,
      # pegging CPU on a resource-constrained Pi actively running its
      # kiosk display, right alongside two other newly-created jobs doing
      # the same thing. A missed day here is a non-issue - see
      # kiosk-gene-desk/persistence.nix's daily/pre-reinstall-cleanup
      # timerConfig overrides for the same reasoning.
      timerConfig = {
        OnCalendar = "daily";
        Persistent = false;
      };
    };
  };
}
