# RustFS: S3-compatible object storage backing the Buzz relay's media and
# git blob storage (hermes-agent-fleet-plan issue #23, ADR 0006). Chosen over
# MinIO — Apache-2.0, ships its own official Nix packaging — but consumed
# here as the prebuilt container image, not the flake's native NixOS module:
# the module requires a from-scratch Rust compile with no binary cache
# (confirmed directly against the upstream flake.nix and README — no
# nixConfig/cachix substituter), while the image is the same official
# artifact, already built. Same reasoning as the podman-container pattern
# already used elsewhere in this directory for upstream-only-published
# services.
#
# Single-node/single-volume (one path in RUSTFS_VOLUMES below) — orico is a
# two-disk ZFS mirror (`zpool status`), which is already the redundancy layer;
# RustFS's own multi-disk erasure coding would just duplicate that.
#
# Loopback-only for the S3 API: Buzz is the only consumer and runs on this
# same host, so there's no reason to widen it — this holds real user content
# (Buzz media uploads, git blob data) behind a single static access/secret
# key pair with no per-device enrollment. The console (a human-facing admin
# UI) is LAN-open instead, matching how the owner accesses other admin UIs
# on this host.
{ config, ... }:
let
  volume_base = "/orico/rustfs";
in
{
  virtualisation.oci-containers.containers.rustfs = {
    autoStart = true;
    environment = {
      RUSTFS_ADDRESS = ":9000";
      RUSTFS_CONSOLE_ADDRESS = ":9001";
      RUSTFS_CONSOLE_ENABLE = "true";
      RUSTFS_OBS_LOGGER_LEVEL = "error";
      RUSTFS_VOLUMES = "/data";
    };
    environmentFiles = [ config.sops.secrets.rustfs_env.path ];
    image = "docker.io/rustfs/rustfs:1.0.0";
    ports = [
      "127.0.0.1:${toString config.genebean.ports.rustfs-api.port}:9000"
      "${toString config.genebean.ports.rustfs-console.port}:9001"
    ];
    volumes = [
      "${volume_base}:/data"
    ];
  };

  # RustFS runs as a fixed non-root uid inside the image (confirmed against
  # upstream's own podman install docs); the host bind-mount directory needs
  # to already be owned by that uid, or the container refuses host-directory
  # binding entirely.
  systemd.tmpfiles.rules = [
    "d ${volume_base} 0750 10001 10001 -"
  ];

  services.restic.backups.daily.paths = [ volume_base ];

  # RUSTFS_ACCESS_KEY=<key>
  # RUSTFS_SECRET_KEY=<secret>
  # Upstream's own docs warn explicitly: never use the well-known
  # "rustfsadmin" default for either value once network-reachable at all,
  # even LAN-only.
  sops.secrets.rustfs_env = {
    restartUnits = [ config.virtualisation.oci-containers.containers.rustfs.serviceName ];
  };
}
