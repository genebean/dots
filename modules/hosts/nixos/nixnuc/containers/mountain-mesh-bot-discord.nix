{ config, username, ... }: let
  volume_base = "/orico/mountain-mesh-bot-discord";
in {
  # My mountain-mesh-bot-discord container

  virtualisation.oci-containers.containers = {
    "mtnmesh_bot_discord" = {
      autoStart = true;
      image = "ghcr.io/genebean/mountain-mesh-bot-discord:v1.0.0";
      volumes = [
        "${volume_base}/.env:/src/.env"
      ];
    };
  };

  services.restic.backups.daily.paths = [ volume_base ];

  sops.secrets.mtnmesh_bot_dot_env = {
    path = "${volume_base}/.env";
    restartUnits = [ "${config.virtualisation.oci-containers.containers.mtnmesh_bot_discord.serviceName}" ];
  };
}
