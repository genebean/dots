{ config, ... }:
let
  volume_base = "/orico/photon";
in
{
  systemd.services."${config.virtualisation.oci-containers.containers.photon.serviceName}" = {
    after = [ "zfs-create-orico-datasets.service" ];
    wants = [ "zfs-create-orico-datasets.service" ];
  };

  virtualisation.oci-containers.containers = {
    "photon" = {
      autoStart = true;
      image = "docker.io/rtuszik/photon-docker:2.3.0";
      environment = {
        REGION = "planet";
        SUPPRESS_BOLTDB_WARNING = "1";
        UPDATE_STRATEGY = "PARALLEL";
        UPDATE_INTERVAL = "30d";
      };
      ports = [ "${toString config.dots.ports.photon.port}:2322" ];
      volumes = [
        "${volume_base}:/photon/data"
      ];
    };
  };

}
