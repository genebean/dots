{ ... }: let
  volume_base = "/var/lib/audiobookshelf";
  http_port = "13378";
in {
  # Audiobookshelf

  virtualisation.oci-containers.containers = {
    "audiobookshelf" = {
      autoStart = true;
      image = "ghcr.io/advplyr/audiobookshelf:2.30.0";
      environment = {
        AUDIOBOOKSHELF_UID = "99";
        AUDIOBOOKSHELF_GID = "100";
      };
      ports = [ "${http_port}:80" ];
      volumes = [
        "${volume_base}/audiobooks:/audiobooks"
        "${volume_base}/podcasts:/podcasts"
        "${volume_base}/printbooks:/printbooks"
        "${volume_base}/config:/config"
        "${volume_base}/metadata:/metadata"
      ];
    };
  };

  services.restic.backups.daily.paths = [ volume_base ];
}
