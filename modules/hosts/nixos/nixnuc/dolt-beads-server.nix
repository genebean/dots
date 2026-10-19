# Central Dolt SQL server backing the shared agents-beads-collaboration
# Beads coordination hub - genebean/dots#825 (design discussion, decisions
# recorded there), genebean/agent-ideas#5 (original two-phase proposal;
# this covers Phase 1 only - the Scotty dashboard is a deliberately
# separate, deferred follow-up).
#
# Every agent/host connects as a normal remote MySQL-protocol client via
# bd's own native `--server --external` mode (confirmed via `bd init
# --help`/`bd dolt --help` against the actual installed nixpkgs-unstable
# build - this is not something to build, only to configure clients
# against) plus `--global` to resolve the fixed `beads_global` database
# name regardless of which project directory a client runs from.
#
# NOT YET DEPLOYED. See dolt-beads-runbook.md in this directory for the
# pre-deploy checklist (secrets that must exist before this can safely go
# live), the migration steps, and the per-agent user-provisioning SQL -
# none of that can be wired into this file yet because sops-nix validates
# that every declared secret actually exists in the encrypted sops file at
# eval time, and those secrets don't exist yet.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "dolt-beads.home.technicalissues.us";
  dataDir = "/orico/dolt-beads";
  doltcfgDir = "${dataDir}/.doltcfg";
  backupDir = "/var/backup/dolt-beads";
  doltPkg = pkgs.dolt;

  serverConfig = pkgs.writeText "dolt-beads-server-config.yaml" ''
    log_level: info
    data_dir: ${dataDir}
    doltcfg_dir: ${doltcfgDir}
    privilege_file: ${doltcfgDir}/privileges.db
    listener:
      host: 0.0.0.0
      port: ${toString config.genebean.ports.dolt-beads.port}
      max_connections: 100
      require_secure_transport: true
      tls_key: ${config.security.acme.certs.${domain}.directory}/key.pem
      tls_cert: ${config.security.acme.certs.${domain}.directory}/fullchain.pem
    metrics:
      port: -1
  '';
in
{
  # Port itself is declared in ./ports.nix (this host's consolidated,
  # port-number-sorted registry) - just read back here.
  users.users.dolt-beads = {
    isSystemUser = true;
    group = "dolt-beads";
    description = "Central Dolt SQL server for the shared Beads coordination hub";
  };
  users.groups.dolt-beads = { };

  # Same shape as mosquitto.nix's own TLS cert on hetznix01 - a service
  # that terminates TLS itself, directly, rather than going through nginx.
  # Picks up the shared DNS-01 Gandi defaults from
  # modules/shared/nixos/lets-encrypt.nix (already imported by this host),
  # no provider config needed here.
  security.acme.certs.${domain} = {
    group = "dolt-beads";
    postRun = "systemctl restart dolt-beads.service";
  };

  systemd = {
    services = {
      dolt-beads = {
        description = "Central Dolt SQL server for the shared Beads coordination hub";
        wantedBy = [ "multi-user.target" ];
        after = [
          "zfs-create-orico-datasets.service"
          "network-online.target"
          "acme-${domain}.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "zfs-create-orico-datasets.service" ];
        serviceConfig = {
          Type = "simple";
          User = "dolt-beads";
          Group = "dolt-beads";
          ExecStart = "${doltPkg}/bin/dolt sql-server --config ${serverConfig}";
          Restart = "on-failure";
          RestartSec = "5s";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          ReadWritePaths = [ dataDir ];
        };
      };

      dolt-beads-backup = {
        description = "Native Dolt snapshot backup of the Beads coordination hub (dump-then-restic, same shape as postgresqlBackup/mysqlBackup)";
        after = [ "dolt-beads.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "dolt-beads";
          Group = "dolt-beads";
        };
        script = ''
          set -euo pipefail
          mkdir -p ${backupDir}
          cd ${dataDir}
          # dolt backup sync-url is Dolt's own native, git-like snapshot
          # mechanism - correctly includes branches/tags/working sets/
          # remote-tracking refs and is safe under concurrent writers,
          # unlike a raw filesystem copy of a live .dolt directory.
          ${doltPkg}/bin/dolt backup sync-url --prune-with-grace-period 1h "file://${backupDir}"
        '';
        startAt = "01:00"; # before this host's own restic_backup_time (02:00)
      };
    };

    tmpfiles.rules = [
      "d ${backupDir} 0750 dolt-beads dolt-beads -"
    ];
  };
}
