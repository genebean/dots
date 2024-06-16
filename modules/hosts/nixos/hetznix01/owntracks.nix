{ config, pkgs, ... }: let
  frontend_port = "8082";
in {
  environment.systemPackages = with pkgs; [
    owntracks-recorder
  ];

  virtualisation.oci-containers.containers = {
    "owntracks-frontend" = {
      autoStart = true;
      image = "docker.io/owntracks/frontend:2.15.3";
      environment = {
        LISTEN = frontend_port;
        SERVER_HOST = config.networking.hostName;
        SERVER_PORT = "8083";
      };
      ports = [ "${frontend_port}:${frontend_port}" ];
    };
  };
}
