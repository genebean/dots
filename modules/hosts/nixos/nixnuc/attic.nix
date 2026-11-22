# Self-hosted Nix binary cache (genebean/dots#677). Public over HTTPS so
# GitHub-hosted CI, Forgejo (running on this same host), and the fleet's
# own hosts can all pull/push from one place instead of every one of them
# rebuilding the same closures independently.
#
# Storage and the sqlite database are pointed directly at orico/attic's own
# natural ZFS mountpoint (/orico/attic), not redirected there via a
# fileSystems "/var/lib/atticd" entry - that first approach hung nixnuc on
# 2026-11-22: ZFS's own automount and the generated var-lib-atticd.mount
# unit both tried to mount the same dataset at once (one at its natural
# /orico/attic path, one at /var/lib/atticd), and neither won cleanly.
# mountpoint=legacy + a fileSystems redirect is only how this host handles
# the services that have NO option to point their state dir elsewhere
# (audiobookshelf, postgresql) - everywhere else (forgejo, dolt-beads,
# jellyfin, ...), the service's own path option just points straight at
# the dataset's natural mountpoint instead, which is what atticd's
# settings.storage.path/settings.database.url being configurable options
# lets it do too.
{ config, pkgs, ... }:
let
  home_domain = "home.technicalissues.us";
  dataDir = "/orico/attic";
in
{
  services.atticd = {
    enable = true;
    # Owner-generated and sops-set, never Claude: `openssl genrsa
    # -traditional 4096 | base64 -w0`, stored as
    # ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 in this secret's file.
    environmentFile = config.sops.secrets.attic_rs256_secret.path;
    settings = {
      allowed-hosts = [ "attic.${home_domain}" ];
      api-endpoint = "https://attic.${home_domain}/";
      database.url = "sqlite://${dataDir}/server.db?mode=rwc";
      # Not keeping much history here - just whatever's currently in use
      # across the fleet and CI, not a long-term archive.
      garbage-collection.default-retention-period = "14 days";
      # Loopback-only - nginx (same host) is the only consumer, matching
      # every other internal-only nixnuc service's backend_ip = 127.0.0.1.
      listen = "127.0.0.1:${toString config.genebean.ports.attic.port}";
      storage = {
        path = "${dataDir}/storage";
        type = "local";
      };
    };
  };

  systemd.services.atticd = {
    after = [ "zfs-create-orico-datasets.service" ];
    requires = [ "zfs-create-orico-datasets.service" ];
    serviceConfig = {
      # The orico/attic dataset is created root-owned by
      # zfs-create-orico-datasets.service - chown it to atticd's own
      # DynamicUser every start, since nothing else does. The "+" prefix
      # runs this one command with full privileges, exempt from the
      # module's own ProtectSystem/ProtectHome/etc below; systemd's
      # dynamic-user NSS registration still resolves the "atticd" name for
      # the duration of this unit's own start, same as any of its other
      # Exec* lines.
      ExecStartPre = "+${pkgs.coreutils}/bin/install -d -o atticd -g atticd -m 0750 ${dataDir}";
      ReadWritePaths = [ dataDir ];
    };
  };
}
