{ config, ... }: let
  http_port = 8080;
  https_port = 8444;
  gandi_api = "${config.sops.secrets.gandi_api.path}";
  #gandi_dns_pat = "${config.sops.secrets.gandi_dns_pat.path}";
in {
  sops.secrets.gandi_api = {
    sopsFile = ../../../../system/common/secrets.yaml;
    restartUnits = [
      "container@nginx-proxy.service"
    ];
  };
  #sops.secrets.gandi_dns_pat = {
  #  sopsFile = ../../../../system/common/secrets.yaml;
  #  restartUnits = [
  #    "container@nginx-proxy.service"
  #  ];
  #};

  containers.nginx-proxy = {
    bindMounts."${gandi_api}".isReadOnly = true;
    #bindMounts."${gandi_dns_pat}".isReadOnly = true;
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
          "nix-tester.h.technicalissues.us" = {
            default = true;
            listen = [
              { port = http_port; addr = "0.0.0.0"; }
              { port = https_port; addr = "0.0.0.0"; }
            ];
            enableACME = true;
            acmeRoot = null;
            forceSSL = false;
          };
        };
      };

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "lets-encrypt@technicalissues.us";
          credentialFiles = { "GANDIV5_API_KEY_FILE" = gandi_api; };
          #credentialFiles = { "GANDIV5_PERSONAL_ACCESS_TOKEN_FILE" = gandi_dns_pat; };
          dnsProvider = "gandiv5";
        };
        # uncomment below for testing
        defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
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
