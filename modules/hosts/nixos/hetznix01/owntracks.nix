{ config, pkgs, ... }: let
  frontend_port = "8082";
in {
  environment = {
    etc = {
      "default/ot-recorder".text = ''
        OTR_USER="recorder"
        OTR_PASS="toenail-madmen-nazareth-fum"
        OTR_GEOKEY="opencage:b85db97221cc4239b34e0ca07e71471e"
        OTR_TOPICS="owntracks/#"
        OTR_HTTPHOST="127.0.0.1"
        OTR_HTTPPREFIX="owntracks"
      '';
    };
  };

  services.mosquitto = {
    enable = true;
    persistence = true;
    listeners = [
      {
        address = "127.0.0.1";
        port = 1883;
        users = {
          recorder.passwordFile = config.sops.secrets.mqtt_recorder_pass.path;
        };
      }
    ];
  };

  users = {
    groups.owntracks.gid = config.users.users.owntracks.uid;
    users.owntracks = {
      isSystemUser = true;
      description = "OwnTracks";
      group = "owntracks";
      home = "/home/owntracks";
    };
  };

  virtualisation.oci-containers.containers = {
    "owntracks-frontend" = {
      autoStart = true;
      image = "docker.io/owntracks/frontend:2.15.3";
      environment = {
        LISTEN = frontend_port;
        SERVER_HOST = "ot-recorder";
      };
      ports = [ "127.0.0.1:${frontend_port}:80" ];
    };
    "ot-recorder" = {
      autoStart = true;
      image = "docker.io/owntracks/frontend:2.15.3";
      ports = [ "127.0.0.1:8083:8083" ];
      volumes = [
        "/etc/default/config:/config"
        "/var/spool/owntracks/recorder/store:/store"
      ];
    };
  };
}
