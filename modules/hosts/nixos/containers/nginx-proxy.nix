{ ... }: {
  containers.nginx-proxy = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br1-23";
    localAddress = "192.168.23.21/24";
    config = { config, pkgs, lib, ... }: {
      system.stateVersion = "23.11";
      services.nginx = {
        enable = true;
        virtualHosts.default.listen = [{
          port = 80;
          addr = "0.0.0.0";
        }];
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 80 ];
        };
        defaultGateway = "192.168.23.1";
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;
      };

      services.resolved.enable = true;
    };
  };
}
