{ config, ... }:
let
  volume_base = "/var/lib/audiobookshelf";
in
{
  # Audiobookshelf

  virtualisation.oci-containers.containers = {
    "audiobookshelf" = {
      autoStart = true;
      image = "ghcr.io/advplyr/audiobookshelf:2.37.2";
      environment = {
        AUDIOBOOKSHELF_UID = "99";
        AUDIOBOOKSHELF_GID = "100";
      };
      ports = [ "${toString config.genebean.ports.audiobookshelf.port}:80" ];
      volumes = [
        "${volume_base}/audiobooks:/audiobooks"
        "${volume_base}/podcast-libraries:/podcast-libraries"
        "${volume_base}/podcasts:/podcasts"
        "${volume_base}/printbooks:/printbooks"
        "${volume_base}/config:/config"
        "${volume_base}/metadata:/metadata"
      ];
    };
  };

  services.restic.backups.daily.paths = [ volume_base ];

  # volume_base is a legacy ZFS mount (hardware-configuration.nix). The OCI
  # module only orders the container after zfs-create-orico-datasets, not after
  # the mount itself. At boot local-fs.target hides that; during a deploy,
  # switch-to-configuration starts the container right after remounting and it
  # can win the race ("statfs /var/lib/audiobookshelf/...: no such file").
  # That one failed start makes the whole activation report failure and
  # deploy-rs rolls the deploy back.
  systemd.services.podman-audiobookshelf.unitConfig.RequiresMountsFor = [ volume_base ];
}
