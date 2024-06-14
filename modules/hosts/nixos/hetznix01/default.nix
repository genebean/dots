{ inputs, config, disko, hostname, pkgs, sops-nix, username,  ... }: let
  http_port = 80;
  https_port = 443;
in {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../../system/common/linux/lets-encrypt.nix
  ];

  system.stateVersion = "23.11";

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a
    # EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking = {
    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      22 # ssh
      80 # http to local Nginx
      443 # https to local Nginx
    ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # firewall.enable = false;

    hostId = "85d0e6cb"; # head -c4 /dev/urandom | od -A none -t x4

    networkmanager.enable = true;
  };

  programs.mtr.enable = true;

  services = {
    fail2ban.enable = true;
    nginx = {
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
        "nue.technicalissues.us" = {
          default = true;
          serverAliases = [ "hetznix01.technicalissues.us" ];
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
        "utk-eu.technicalissues.us" = {
          listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyWebsockets = true;
          locations."/".proxyPass = "http://127.0.0.1:3001";
        };
      }; # end virtualHosts
    }; # end nginx
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_key.path;
      extraUpFlags = [
        "--advertise-exit-node"
        "--operator"
        "${username}"
        "--ssh"
      ];
      useRoutingFeatures = "both";
    };
    uptime-kuma = {
      enable = true;
      settings = {
        UPTIME_KUMA_HOST = "127.0.0.1";
        #UPTIME_KUMA_PORT = "3001";
      };
    };
  };

  sops = {
    age.keyFile = /home/${username}/.config/sops/age/keys.txt;
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_git_config = {
        owner = "${username}";
        path = "/home/${username}/.gitconfig-local";
      };
      local_private_env = {
        owner = "${username}";
        path = "/home/${username}/.private-env";
      };
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  };

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      address = [
        "167.235.18.32/32"
        "2a01:4f8:c2c:2e49::1/64"
      ];
      dns = [
        "185.12.64.1"
        "185.12.64.2"
        "2a01:4ff:ff00::add:1"
        "2a01:4ff:ff00::add:2"
      ];
      routes = [
        { routeConfig = { Destination = "172.31.1.1"; }; }
        { routeConfig = { Gateway = "172.31.1.1"; GatewayOnLink = true; }; }
        { routeConfig.Gateway = "fe80::1"; }
      ];
      # make the routes on this interface a dependency for network-online.target
      linkConfig.RequiredForOnline = "routable";
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBjigwV0KnnaTnFmKjjvnULa5X+hvsy2FAlu+lUUY59f gene@rainbow-planet"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N bluerock"
    ];
  };
}
