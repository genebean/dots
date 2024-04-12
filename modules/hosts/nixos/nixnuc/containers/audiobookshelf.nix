{ ... }: let
  volume_base = "/orico/audiobookshelf";
  http_port = "13378";
in {
  # Audiobookshelf

  #############################################################################
  # I am using v2.8.1 because that is both the current Docker image and       #
  # the current version in nixpkgs unstable. My plan is to switch from Podman #
  # to a systemd-nspawn container.                                            #
  #############################################################################

  virtualisation.oci-containers.containers = {
    "audiobookshelf" = {
      autoStart = true;
      image = "ghcr.io/advplyr/audiobookshelf:2.8.1";
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
