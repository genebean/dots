{ inputs, config, pkgs, username,  ... }: let
  http_port = 80;
  https_port = 443;
  home_domain = "home.technicalissues.us";
  backend_ip = "127.0.0.1";
  mini_watcher = "192.168.23.20";
in {
  imports = [
    ./hardware-configuration.nix
    ./containers/audiobookshelf.nix
    ./containers/psitransfer.nix
    ../../common/linux/lets-encrypt.nix
    ../../common/linux/restic.nix
  ];

  system.stateVersion = "23.11";

  # Bootloader.
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs = {
      extraPools = [ "orico" ];
      forceImportRoot = false;
    };
  };

  environment.systemPackages = with pkgs; [
    inputs.compose2nix.packages.${pkgs.system}.default
    docker-compose
    intel-gpu-tools
    jellyfin
    jellyfin-ffmpeg
    jellyfin-web
    net-snmp
    nginx
    podman-compose
    podman-tui # status of containers in the terminal
    yt-dlp
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    ];
  };
  
  mailserver = {
    enable = true;
    enableImap = false;
    enableImapSsl = false;
    fqdn = "mail.${home_domain}";
    domains = [
      home_domain
    ];
    forwards = {
      "${username}@localhost" = "${username}@technicalissues.us";
      "root@localhost" = "root@technicalissues.us";
      "root@${config.networking.hostName}" = "root@technicalissues.us";
    };

    # Use Let's Encrypt certificates from Nginx
    certificateScheme = "acme";
  };

  networking = {
    # Open ports in the firewall.
    firewall = {
      allowedTCPPorts = [
        22    # ssh
        80    # http to local Nginx
        443   # https to local Nginx
        3000  # PsiTransfer in oci-container
        3001  # immich-kiosk in compose
        3030  # Forgejo
        8001  # Tube Archivist
        8384  # Syncthing gui
        8888  # Atuin
        8090  # Wallabag in docker compose
        13378 # Audiobookshelf in oci-container
        22000 # Syncthing transfers
      ];
      allowedUDPPorts = [
         1900 # Jellyfin service auto-discovery
         7359 # Jellyfin auto-discovery
        21027 # Syncthing discovery
        22000 # Syncthing transfers
      ];
    };
    # Or disable the firewall altogether.
    # firewall.enable = false;

    hostId = "c5826b45"; # head -c4 /dev/urandom | od -A none -t x4

    useDHCP = false;
    networkmanager.enable = false;
    useNetworkd = true;
    vlans = {
      vlan23 = { id = 23; interface = "eno1"; };
    };
    interfaces = {
      eno1.useDHCP = true;
      vlan23.ipv4.addresses = [{ address = "192.168.23.21"; prefixLength = 24; }];
    };
  };

  # Hardware Transcoding for Jellyfin
  nixpkgs.overlays = [
    (self: super: {
      # "vaapiIntel" is in some docs, but that is an alias
      # to intel-vaapi-driver as of 2023-05-31
      intel-vaapi-driver = super.intel-vaapi-driver.override {
        enableHybridCodec = true;
      };
    })
  ];

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.mtr.enable = true;

  # List services that you want to enable:
  services = {
    atuin = {
      enable = true;
      host = "127.0.0.1";
      maxHistoryLength = 2000000000;
    };
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
    ddclient = {
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
      passwordFile = "${config.sops.secrets.gandi_api.path}";
    };
    forgejo = {
      enable = true;
      database.type = "postgres";
      lfs.enable = true;
      settings = {
        # Add support for actions, based on act: https://github.com/nektos/act
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };
        DEFAULT.APP_NAME = "Beantown's Code";
        repository = {
          DEFAULT_PUSH_CREATE_PRIVATE = true;
          ENABLE_PUSH_CREATE_ORG = true;
          ENABLE_PUSH_CREATE_USER = true;
        };
        server = {
          DOMAIN = "git.${home_domain}";
          HTTP_PORT = 3030;
          LANDING_PAGE = "explore";
          ROOT_URL = "https://git.${home_domain}/";
        };
        service.DISABLE_REGISTRATION = true;
        session.COOKIE_SECURE = true;
      };
      stateDir = "/orico/forgejo";
    };
    fwupd.enable = true;
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    lldpd.enable = true;
    mealie = {
      enable = true;
      credentialsFile = config.sops.secrets.mealie.path;
      listenAddress = "0.0.0.0";
      port = 9000;
      settings = {
        ALLOW_SIGNUP = "false";
        BASE_URL = "https://mealie.${home_domain}";
        DATA_DIR = "/var/lib/mealie";
        DB_ENGINE = "postgres";
        POSTGRES_USER = "mealie";
        POSTGRES_DB = "mealie";
        POSTGRES_SERVER = "localhost";
        POSTGRES_PORT = config.services.postgresql.settings.port;
        SMTP_HOST = "localhost";
        SMTP_PORT = 25;
        SMTP_FROM_NAME = "Mealie";
        SMTP_FROM_EMAIL = "mealie@${home_domain}";
        SMTP_AUTH_STRATEGY = "NONE";
      };
    };
    nextcloud = {
      enable = true;
      hostName = "nextcloud.home.technicalissues.us";
      package = pkgs.nextcloud30; # Need to manually increment with every major upgrade.
      appstoreEnable = true;
      autoUpdateApps.enable = true;
      config = {
        adminuser = username;
        adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
        dbtype = "pgsql";
      };
      configureRedis = true;
      database.createLocally = true;
      #extraApps = with config.services.nextcloud.package.packages.apps; {
      #  # List of apps we want to install and are already packaged in
      #  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
      #  inherit calendar contacts cookbook maps notes tasks;
      #};
      #extraAppsEnable = true;
      home = "/orico/nextcloud";
      https = true;
      maxUploadSize = "100G"; # Increase the PHP maximum file upload size
      phpOptions."opcache.interned_strings_buffer" = "16"; # Suggested by Nextcloud's health check.
      settings = {
        default_phone_region = "US";
        # https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#enabledpreviewproviders
        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"

          "OC\\Preview\\HEIC"
          "OC\\Preview\\Movie"
        ];
        log_type = "file";
        maintenance_window_start = 5;
        overwriteProtocol = "https";
        "profile.enabled" = true;
      };
    };
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
            https   "max-age=31536000;";
        }
        add_header Strict-Transport-Security $hsts_header;
      '';
      virtualHosts = {
        "${home_domain}" = {
          default = true;
          serverAliases = [
            "mail.${home_domain}"
            "nix-tester.${home_domain}"
          ];
          listen = [
            { port = https_port; addr = "0.0.0.0"; ssl = true; }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
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
          locations."/".proxyPass = "http://${backend_ip}:13378";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "atuin.${home_domain}" = {
          listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:8888";
        };
        "git.${home_domain}" = {
          listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:3030";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "immich.${home_domain}" = {
          listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:2283";
          locations."/".proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout       600s;
          '';
        };
        "jellyfin.${home_domain}" = {
          listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${backend_ip}:8096";
              extraConfig = ''
                proxy_buffering off;
                proxy_set_header X-Forwarded-Protocol $scheme;
              '';
            };
            "/socket" = {
              proxyPass = "http://${backend_ip}:8096";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header X-Forwarded-Protocol $scheme;
              '';
            };
          };
          extraConfig = ''
            client_max_body_size 20M;
          '';
        };
        "mealie.${home_domain}" = {
          listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:9000";
          extraConfig = ''
            client_max_body_size 10M;
          '';
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
        "nextcloud.${home_domain}" = {
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
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
          locations."/".proxyPass = "http://${backend_ip}:8090";
        };
      };
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
    };
    postgresqlBackup = {
      enable = true;
      backupAll = true;
      startAt = "*-*-* 23:00:00";
    };
    resolved.enable = true;
    restic.backups.daily.paths = [
      config.services.forgejo.stateDir
      config.services.mealie.settings.DATA_DIR
      config.services.nextcloud.home
      "${config.users.users.${username}.home}/compose-files/wallabag"
      "/orico/immich/library"
      "/orico/jellyfin/data"
      "/orico/jellyfin/staging/downloaded-files"
      "/var/backup/postgresql"
    ];
    syncthing = {
      enable = true;
      dataDir = "/orico/syncthing";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";
    };
    zfs.autoScrub.enable = true;
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_git_config = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.gitconfig-local";
      };
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
      mealie.mode = "0444";
      nextcloud_admin_pass.owner = config.users.users.nextcloud.name;
    };
  };

  systemd.services = {
    "mealie" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };
    "nextcloud-setup" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "docker" "podman" "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvLaPTfG3r+bcbI6DV4l69UgJjnwmZNCQk79HXyf1Pt gene@rainbow-planet"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N gene.liverman@ltnglobal.com"
    ];
  };

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;

  virtualisation.oci-containers.backend = "podman";

  # Compose based apps were crashing with podman compose, so back to Docker...
  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_26;

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    #dockerCompat = true;
    extraPackages = [ pkgs.zfs ]; # Required if the host is running ZFS

    # Required for container networking to be able to use names.
    defaultNetwork.settings.dns_enabled = true;
  };
}
