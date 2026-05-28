{ config, ... }:
let
  volume_base = "/orico/photon";
  http_port = "2322";
in
{
  systemd.services."${config.virtualisation.oci-containers.containers.photon.serviceName}" = {
    after = [ "zfs-create-orico-datasets.service" ];
    wants = [ "zfs-create-orico-datasets.service" ];
  };

  virtualisation.oci-containers.containers = {
    "photon" = {
      autoStart = true;
      image = "docker.io/rtuszik/photon-docker:latest";
      environment = {
        REGION = "planet";
        UPDATE_STRATEGY = "PARALLEL";
        UPDATE_INTERVAL = "30d";
      };
      ports = [ "${http_port}:2322" ];
      volumes = [
        "${volume_base}:/photon/data"
      ];
    };
  };

}
