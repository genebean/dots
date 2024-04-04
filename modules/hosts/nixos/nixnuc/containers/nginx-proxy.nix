{ ... }: let
  http_port = 8080;
  https_port = 8444;
in {
  containers.nginx-proxy = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "br1-23";
    localAddress = "192.168.23.21/24";
    config = { config, pkgs, lib, ... }: {
      system.stateVersion = "23.11";
      services.nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        virtualHosts = {
          "nix-tester.home.technicalissues.us" = {
            default = true;
            listen = [
              { port = http_port; addr = "0.0.0.0"; }
              { port = https_port; addr = "0.0.0.0"; }
            ];
            enableACME = true;
            forceSSL = false;
          };
        };
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "lets-encrypt@technicalissues.us";
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ http_port https_port ];
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
