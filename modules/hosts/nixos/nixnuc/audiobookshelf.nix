{ ... }: let
  volume_base = "/orico/audiobookshelf";
in {
  # Audiobookshelf
  virtualisation.oci-containers.containers = {
    "audiobookshelf" = {
      autoStart = true;
      image = "ghcr.io/advplyr/audiobookshelf:latest";
      environment = {
        AUDIOBOOKSHELF_UID = "99";
        AUDIOBOOKSHELF_GID = "100";
      };
      ports = [ "13378:80" ];
      volumes = [
        "${volume_base}/audiobooks:/audiobooks"
        "${volume_base}/podcasts:/podcasts"
        "${volume_base}/printbooks:/printbooks"
        "${volume_base}/config:/config"
        "${volume_base}/metadata:/metadata"
      ];
    };
  };
}
