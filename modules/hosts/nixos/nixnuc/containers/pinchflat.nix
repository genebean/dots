{ config, ... }: let
  volume_base = "/orico/pinchflat";
  jellyfin_youtube = "/orico/jellyfin/data/YouTube";
  container_user = "jellyfin";
  uid = "990";
  gid = "989";
in {
  virtualisation.oci-containers.containers = {
    "pinchflat" = {
      autoStart = true;
      environmentFiles = [
        "${volume_base}/.env"
      ];
      extraOptions = [
        "--security-opt"
        "label=disable"
        "--userns=keep-id"
      ];
      image = "ghcr.io/kieraneglin/pinchflat:latest";
      ports = [
        "8945:8945"
      ];
      user = "${uid}:${gid}"; # observed UID:GID of jellyfin user
      volumes = [
        "${volume_base}/config:/config"
        "${jellyfin_youtube}:/downloads"
      ];
    };
  };

  services.restic.backups.daily.paths = [ volume_base ];

  sops.secrets.pinchflat_dot_env = {
    owner = "${container_user}";
    path = "${volume_base}/.env";
    restartUnits = [ "${config.virtualisation.oci-containers.containers.pinchflat.serviceName}" ];
  };
}

