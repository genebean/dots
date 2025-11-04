{ config, username, ... }: let
  volume_base = "/var/lib/emqx";
in {
  # Based on docs at https://docs.emqx.com/en/emqx/latest/deploy/install-docker.html
  virtualisation.oci-containers.containers = {
    "emqx" = {
      autoStart = true;
      image = "docker.io/emqx/emqx-enterprise:5.10.0";
      environment = {
        EMQX_NODE_NAME = "emqx@emqx1.hetznix01.technicalissues.us";
      };
      environmentFiles = [
        "${volume_base}/.env"
      ];
      hostname = "emqx1.hetznix01.technicalissues.us";
      ports = [
        "1883:1883"
        #"8083:8083"
        #"8084:8084"
        "18083:18083"
      ];
      volumes = [
        "${volume_base}/data:/opt/emqx/data"
        "${volume_base}/log:/opt/emqx/log"
      ];
    };
  };

  services.restic.backups.daily.paths = [ "${volume_base}/data" ];

  sops.secrets.emqx_env = {
    path = "${volume_base}/.env";
    owner = username;
    restartUnits = [ "${config.virtualisation.oci-containers.containers.emqx.serviceName}" ];
  };
}
