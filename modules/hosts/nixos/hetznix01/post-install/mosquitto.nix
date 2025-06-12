{ config, ... }: let
  mqtt_domain = "mqtt.technicalissues.us";
in {
  security.acme.certs.${mqtt_domain}.postRun = "systemctl restart ${config.systemd.services.mosquitto.name}";

  services.mosquitto = {
    enable = true;
    bridges = {
      liamcottle = {
        addresses = [{
          address = "mqtt.meshtastic.liamcottle.net";
          port = 1883;
        }];
        topics = [
          "msh/# out 1 \"\""
        ];
        settings = {
          remote_username = "uplink";
          remote_password = "uplink";
          cleansession = true;
          keepalive_interval = 160;
          notifications = false;
          start_type = "automatic";
        };
      };
      meshtastic = {
        addresses = [{
          address = "mqtt.meshtastic.org";
          port = 1883;
        }];
        topics = [
          "msh/# out 1 \"\""
        ];
        settings = {
          remote_username = "meshdev";
          remote_password = "large4cats";
          #bridge_protocol_version = "mqttv311";
          cleansession = true;
          keepalive_interval = 160;
          notifications = false;
          start_type = "automatic";
        };
      };
      homeassistant = {
        addresses = [{
          address = "homeasistant-lc.atlas-snares.ts.net";
          port = 1883;
        }];
        topics = [
          "msh/US/2/e/LongFast/!a386c80 out 1 \"\""
          "msh/US/2/e/LongFast/!b03bcb24 out 1 \"\""
          "msh/US/2/e/LongFast/!b03dbe58 out 1 \"\""
          "msh/US/2/e/LongFast/!4370b0c6 out 1 \"\""
        ];
        settings = {
          remote_username = "meshtastic_user";
          remote_password = "meshtastic_user";
          cleansession = true;
          keepalive_interval = 160;
          notifications = false;
          start_type = "automatic";
        };
      };
    };
    listeners = let
      mqtt_users = {
        genebean = {
          acl = [
            "readwrite msh/#"
          ];
          hashedPasswordFile = config.sops.secrets.mosquitto_genebean.path;
        };
        mountain_mesh = {
          acl = [
            "readwrite msh/#"
          ];
          hashedPasswordFile = config.sops.secrets.mosquitto_mountain_mesh.path;
        };
      };
    in [
      {
        port = 1883;
        users = mqtt_users;
        settings.allow_anonymous = false;
      }
      {
        port = 8883;
        users = mqtt_users;
        settings = let
          certDir = config.security.acme.certs."${mqtt_domain}".directory;
        in {
          allow_anonymous = false;
          keyfile = certDir + "/key.pem";
          certfile = certDir + "/cert.pem";
          cafile = certDir + "/chain.pem";
        };
      }
      {
        port = 9001;
        users = mqtt_users;
        settings = let
          certDir = config.security.acme.certs."${mqtt_domain}".directory;
        in {
          allow_anonymous = false;
          keyfile = certDir + "/key.pem";
          certfile = certDir + "/cert.pem";
          cafile = certDir + "/chain.pem";
          protocol = "websockets";
        };
      }
    ];
  };

  sops.secrets = {
    mosquitto_genebean.owner = config.users.users.mosquitto.name;
    mosquitto_mountain_mesh.owner = config.users.users.mosquitto.name;
  };

  users.users.mosquitto.extraGroups = [ "nginx" ];
}
