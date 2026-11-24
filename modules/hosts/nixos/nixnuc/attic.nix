# Self-hosted Nix binary cache (genebean/dots#677). Public over HTTPS so
# GitHub-hosted CI, Forgejo (running on this same host), and the fleet's
# own hosts can all pull/push from one place instead of every one of them
# rebuilding the same closures independently.
#
# Storage is pointed directly at /attic, a dedicated ext4 partition on its
# own NVMe disk (hardware-configuration.nix) - not the orico ZFS pool.
# orico's slower member (a USB3.0 mirror disk) bottlenecked real pushes to
# sub-1MB/s, badly enough to make it unusable in practice (confirmed live,
# not assumed). bcachefs (matching tcan-left) was the first choice, but
# ruled out here specifically: nixnuc also needs ZFS for orico, and the
# only kernel line that avoids the bcachefs-tools/kernel-6.18
# incompatibility (NixOS/nixpkgs issue 591440) is linuxPackages_latest,
# which breaks ZFS's own kernel module instead (confirmed: zfs_2_4.meta.broken
# is true there). No kernel in this nixpkgs revision supports both at once.
#
# The database moved from sqlite to PostgreSQL: sqlite's single-writer
# lock was the actual bottleneck once the storage bottleneck above was
# fixed - confirmed live via iostat (the NVMe itself idle, Postgres
# unaffected) and a real "Connection pool timed out" error atticd logged
# under concurrent chunk uploads. This reuses this host's existing
# services.postgresql server (default.nix), but NOT its existing
# orico-backed data directory - that's the same slow ZFS pool the storage
# move above was fixing, and reusing it would reintroduce that same
# problem via a different path. Instead, Postgres gets a dedicated
# tablespace on /attic's own NVMe (default.nix's systemd.services.postgresql
# override), keeping Attic's data physically where its storage files
# already live while still getting MVCC's concurrent-writer benefit.
# Peer-authenticated over the unix socket (no password - atticd's own OS
# user matches a same-named Postgres role via NixOS's default "local all
# all peer" pg_hba rule), so no secret ever needs to go into atticd's
# rendered config file in the (world-readable) Nix store.
{ config, pkgs, ... }:
let
  home_domain = "home.technicalissues.us";
  dataDir = "/attic";
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
      # Peer auth via the unix socket - see the module header comment for
      # why. The "attic" database and its "attic_fast" tablespace are a
      # one-time manual bootstrap (attic-postgres-cutover.md in this
      # directory), not something ensureDatabases can express.
      database.url = "postgresql:///attic?host=/run/postgresql";
      # Not keeping much history here - just whatever's currently in use
      # across the fleet and CI, not a long-term archive.
      garbage-collection.default-retention-period = "32 days";
      # All interfaces, matching how the rest of the fleet's internal-only
      # services already bind - nginx moved to pigate, reaching this over
      # the services VLAN instead of loopback.
      listen = "0.0.0.0:${toString config.genebean.ports.attic.port}";
      storage = {
        path = "${dataDir}/storage";
        type = "local";
      };
    };
  };

  systemd.services.atticd = {
    # attic.mount is systemd's auto-generated unit for the /attic
    # fileSystems entry (hardware-configuration.nix).
    after = [ "attic.mount" ];
    requires = [ "attic.mount" ];
    serviceConfig = {
      # /attic is a bare ext4 mount, root-owned by default - chown it to
      # atticd's own DynamicUser every start, since nothing else does.
      # The "+" prefix runs this one command with full privileges, exempt
      # from the module's own ProtectSystem/ProtectHome/etc below;
      # systemd's dynamic-user NSS registration still resolves the
      # "atticd" name for the duration of this unit's own start, same as
      # any of its other Exec* lines. Mode 0751, not 0750: postgres (a
      # different, static UID, not in atticd's dynamic group) needs to
      # traverse into /attic to reach its own tablespace subdirectory
      # below - confirmed live that 0750 blocked it entirely with
      # "Permission denied" on CREATE TABLESPACE, before postgres ever got
      # to check that subdirectory's own (still-restrictive) permissions.
      # The extra +x is traversal-only, not read - atticd's actual files
      # (storage/, server.db*) keep their own tighter permissions.
      ExecStartPre = "+${pkgs.coreutils}/bin/install -d -o atticd -g atticd -m 0751 ${dataDir}";
      ReadWritePaths = [ dataDir ];
    };
  };
}
