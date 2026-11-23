# Self-hosted Nix binary cache (genebean/dots#677). Public over HTTPS so
# GitHub-hosted CI, Forgejo (running on this same host), and the fleet's
# own hosts can all pull/push from one place instead of every one of them
# rebuilding the same closures independently.
#
# Storage and the sqlite database are pointed directly at /attic, a
# dedicated ext4 partition on its own NVMe disk (hardware-configuration.nix)
# - not the orico ZFS pool. orico's slower member (a USB3.0 mirror disk)
# bottlenecked real pushes to sub-1MB/s, badly enough to make it
# unusable in practice (confirmed live, not assumed). bcachefs (matching
# tcan-left) was the first choice, but ruled out here specifically:
# nixnuc also needs ZFS for orico, and the only kernel line that avoids
# the bcachefs-tools/kernel-6.18 incompatibility (NixOS/nixpkgs issue
# 591440) is linuxPackages_latest, which breaks ZFS's own kernel module
# instead (confirmed: zfs_2_4.meta.broken is true there). No kernel in
# this nixpkgs revision supports both at once.
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
      database.url = "sqlite://${dataDir}/server.db?mode=rwc";
      # Not keeping much history here - just whatever's currently in use
      # across the fleet and CI, not a long-term archive.
      garbage-collection.default-retention-period = "32 days";
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
      # any of its other Exec* lines.
      ExecStartPre = "+${pkgs.coreutils}/bin/install -d -o atticd -g atticd -m 0750 ${dataDir}";
      ReadWritePaths = [ dataDir ];
    };
  };
}
