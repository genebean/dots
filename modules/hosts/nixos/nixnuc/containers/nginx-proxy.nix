{ config, ... }: let
  http_port = 8080;
  https_port = 8444;
  gandi_api = "${config.sops.secrets.gandi_api.path}";
  #gandi_dns_pat = "${config.sops.secrets.gandi_dns_pat.path}";
  home_domain = "home.technicalissues.us";
  backend_ip = "192.168.20.190";
  mini_watcher = "192.168.23.20";
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

  ##
  ## Gandi (gandi.net)
  ##
  ## Single host update
  # protocol=gandi
  # zone=example.com
  # password=my-gandi-access-token
  # use-personal-access-token=yes
  # ttl=10800 # optional
  # myhost.example.com
  services.ddclient = {
    enable = true;
    protocol = "gandi";
    zone = "technicalissues.us";
    domains = [ home_domain ];
    username = "unused";
    extraConfig = ''
      usev4=webv4
      #usev6=webv6
      #use-personal-access-token=yes
      ttl=300
    '';
    passwordFile = gandi_api; };

  containers.nginx-proxy = {
    bindMounts."${gandi_api}".isReadOnly = true;
    #bindMounts."${gandi_dns_pat}".isReadOnly = true;
    autoStart = true;
    timeoutStartSec = "5min";
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
        appendHttpConfig = ''
          # Add HSTS header with preloading to HTTPS requests.
          # Adding this header to HTTP requests is discouraged
          map $scheme $hsts_header {
              https   "max-age=31536000 always;";
          }
          add_header Strict-Transport-Security $hsts_header;
        '';

        virtualHosts = {
          "${home_domain}" = {
            serverAliases = [ "nix-tester.${home_domain}" ];
            default = true;
            listen = [
              { port = http_port; addr = "0.0.0.0"; }
              { port = https_port; addr = "0.0.0.0"; ssl = true; }
            ];
            enableACME = true;
            acmeRoot = null;
            addSSL = true;
            forceSSL = false;
            locations."/" = {
              return = "200 '<h1>Hello world ;)</h1>'";
              extraConfig = ''
                add_header Content-Type text/html;
              '';
            };
          };
          "ab.${home_domain}" = {
            listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
            enableACME = true;
            acmeRoot = null;
            forceSSL = true;
            locations."/".proxyWebsockets = true;
            locations."/".proxyPass = "http://${mini_watcher}:13378";
          };
          "atuin.${home_domain}" = {
            listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
            enableACME = true;
            acmeRoot = null;
            forceSSL = true;
            locations."/".proxyPass = "http://${mini_watcher}:9999";
          };
          "nc.${home_domain}" = {
            listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
            enableACME = true;
            acmeRoot = null;
            forceSSL = true;
            extraConfig = ''
              client_max_body_size 0;
              underscores_in_headers on;
            '';
            locations."/".proxyWebsockets = true;
            locations."/".proxyPass = "http://${mini_watcher}:8081";
            locations."/".extraConfig = ''
              # these are added per https://www.nicemicro.com/tutorials/debian-snap-nextcloud.html
              add_header Front-End-Https on;
              proxy_headers_hash_max_size 512;
              proxy_headers_hash_bucket_size 64;
              proxy_buffering off;
              proxy_max_temp_file_size 0;
            '';
          };
          "onlyoffice.${home_domain}" = {
            listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
            enableACME = true;
            acmeRoot = null;
            forceSSL = true;
            locations."/".proxyWebsockets = true;
            locations."/".proxyPass = "http://${mini_watcher}:8888";
          };
          "readit.${home_domain}" = {
            listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
            enableACME = true;
            acmeRoot = null;
            forceSSL = true;
            locations."/".proxyPass = "http://${mini_watcher}:8090";
          };
          "tandoor.${home_domain}" = {
            listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
            enableACME = true;
            acmeRoot = null;
            forceSSL = true;
            locations."/".proxyPass = "http://${mini_watcher}:8080";
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
          dnsResolver = "ns1.gandi.net";
          # uncomment below for testing
          #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        };
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
