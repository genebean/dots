{
  inputs,
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  home_domain = "home.technicalissues.us";
  backend_ip = "127.0.0.1";
  restic_backup_time = "02:00";
in
{
  imports = [
    ./hardware-configuration.nix
    ./containers/audiobookshelf.nix
    ./containers/mountain-mesh-bot-discord.nix
    ./containers/photon.nix
    ./containers/psitransfer.nix
    ./cup-collector.nix
    ./monitoring-stack.nix
    ./ports.nix
    ./zfs-datasets.nix
    ../../../shared/nixos/lets-encrypt.nix
    ../../../shared/nixos/ports.nix
    ../../../shared/nixos/restic.nix
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

  environment = {
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
    systemPackages = with pkgs; [
      inputs.compose2nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      docker-compose
      intel-gpu-tools
      jellyfin
      jellyfin-ffmpeg
      jellyfin-web
      net-snmp
      nginx
      nvme-cli
      podman-compose
      podman-tui # status of containers in the terminal
      yt-dlp
    ];
  };

  # https://wiki.nixos.org/wiki/Jellyfin
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime-legacy1 # pre-13th gen cpu
      intel-media-driver # For Broadwell and newer (ca. 2014+), use with LIBVA_DRIVER_NAME=iHD:
      intel-ocl # Generic OpenCL support
    ];
  };

  networking = {
    firewall = {
      allowedTCPPorts = lib.pipe config.dots.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "tcp"))
        (map (e: e.port))
      ];
      allowedUDPPorts = lib.pipe config.dots.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "udp"))
        (map (e: e.port))
      ];
    };

    hostId = "c5826b45"; # head -c4 /dev/urandom | od -A none -t x4

    useDHCP = false;
    networkmanager.enable = false;
    useNetworkd = true;
    vlans = {
      vlan23 = {
        id = 23;
        interface = "eno1";
      };
    };
    interfaces = {
      eno1.useDHCP = true;
      vlan23.ipv4.addresses = [
        {
          address = "192.168.23.21";
          prefixLength = 24;
        }
      ];
    };
  };

  # Enable sound with pipewire.
  security.rtkit.enable = true;

  programs = {
    mtr.enable = true;
  };

  # List services that you want to enable:
  services = {
    atuin = {
      enable = true;
      host = "127.0.0.1";
      maxHistoryLength = 2000000000;
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
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
        use-personal-access-token=yes
        ttl=300
      '';
      passwordFile = "${config.sops.secrets.gandi_dns_pat.path}";
    };
    firefly-iii = {
      enable = true;
      enableNginx = true;
      settings.APP_KEY_FILE = "${config.sops.secrets.firefly_app_key.path}";
      virtualHost = "budget.${home_domain}";
    };
    firefly-iii-data-importer = {
      enable = true;
      enableNginx = true;
      settings = {
        FIREFLY_III_URL = "http://localhost:${toString config.dots.ports.fireflyiii.port}";
        VANITY_URL_FILE = "${config.sops.secrets.firefly_vanity_url.path}";
        FIREFLY_III_ACCESS_TOKEN_FILE = "${config.sops.secrets.firefly_pat_data_import.path}";
        SIMPLEFIN_TOKEN_FILE = "${config.sops.secrets.firefly_simplefin_token.path}";
        TZ = "America/New_York";
      };
      virtualHost = "budget-importer.${home_domain}";
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
          HTTP_PORT = config.dots.ports.forgejo.port;
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
      inherit (config.dots.ports.mealie) port;
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
      package = pkgs.nextcloud33; # Need to manually increment with every major upgrade.
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
      fastcgiTimeout = 3600;
      home = "/orico/nextcloud";
      https = true;
      maxUploadSize = "100G"; # Increase the PHP maximum file upload size
      phpOptions = {
        "max_execution_time" = "3600";
        "max_input_time" = "3600";
        "opcache.interned_strings_buffer" = "16"; # Suggested by Nextcloud's health check.
        "upload_tmp_dir" = "/orico/nextcloud/php-upload-tmp";
      };
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

        # Rate-limit the ytdlfin health endpoint so unauthenticated bots
        # can't hammer it.  Uptime Kuma polls once per minute; 6r/m gives
        # comfortable headroom while still blocking floods.
        limit_req_zone $binary_remote_addr zone=ytdlfin_health:1m rate=6r/m;
      '';
      virtualHosts = {
        "${home_domain}" = {
          default = true;
          serverAliases = [
            "nix-tester.${home_domain}"
          ];
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
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
          locations."/server_status" = {
            extraConfig = ''
              stub_status;
              allow 127.0.0.1;
              deny all;
            '';
          };
        };
        "ab.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyWebsockets = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.audiobookshelf.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "atuin.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.atuin.port}";
        };
        # budget.${home_domain}
        "${config.services.firefly-iii.virtualHost}".listen = [
          {
            inherit (config.dots.ports.fireflyiii) port;
            addr = "0.0.0.0";
            ssl = false;
          }
        ];
        "${config.services.firefly-iii-data-importer.virtualHost}".listen = [
          {
            inherit (config.dots.ports.fireflyiii-importer) port;
            addr = "0.0.0.0";
            ssl = false;
          }
        ];
        "git.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.forgejo.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "id.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.pocket-id.port}";
          extraConfig = ''
            proxy_busy_buffers_size   512k;
            proxy_buffers           4 512k;
            proxy_buffer_size         256k;
          '';
        };
        "immich.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.immich.port}";
          locations."/".proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout       600s;
          '';
        };
        "immich-kiosk.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          basicAuthFile = config.sops.secrets.immich_kiosk_basic_auth.path;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.immich-kiosk.port}";
          locations."/".proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout       600s;
          '';
        };
        "jellyfin.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${backend_ip}:${toString config.dots.ports.jellyfin.port}";
              extraConfig = ''
                proxy_buffering off;
                proxy_set_header X-Forwarded-Protocol $scheme;
              '';
            };
            "/socket" = {
              proxyPass = "http://${backend_ip}:${toString config.dots.ports.jellyfin.port}";
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
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.mealie.port}";
          extraConfig = ''
            client_max_body_size 10M;
          '';
        };
        "monitoring.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/grafana/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.grafana.port}/grafana/";
            "/remotewrite" = {
              basicAuthFile = config.sops.secrets.nginx_basic_auth.path;
              proxyPass = "http://127.0.0.1:${toString config.dots.ports.victoriametrics.port}/api/v1/write";
              proxyWebsockets = true;
            };
          };
        };
        "nextcloud.${home_domain}" = {
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
        };
        "readit.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.wallabag.port}";
        };
        "ytdlfin.${home_domain}" = {
          listen = [
            {
              inherit (config.dots.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.dots.ports.ytdlfin.port}";
          locations."= /health" = {
            proxyPass = "http://${backend_ip}:${toString config.dots.ports.ytdlfin.port}";
            extraConfig = ''
              limit_req zone=ytdlfin_health burst=3 nodelay;
            '';
          };
        };
      };
    };
    pinchflat = {
      enable = true;
      group = "jellyfin";
      mediaDir = "/orico/jellyfin/data/Pinchflat";
      selfhosted = true; # Only because this is not exsposed to the web
      user = "jellyfin";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    pocket-id = {
      enable = true;
      credentials = {
        ENCRYPTION_KEY = config.sops.secrets.pocketid_encryption_key.path;
      };
      settings = {
        APP_URL = "https://id.${home_domain}";
        TRUST_PROXY = true;
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
    pulseaudio.enable = false;
    resolved.enable = true;
    restic.backups.daily = {
      paths = [
        config.services.forgejo.stateDir
        config.services.mealie.settings.DATA_DIR
        config.services.nextcloud.home
        "${config.users.users.${username}.home}/compose-files/wallabag"
        "/orico/immich/library"
        "/orico/jellyfin/data"
        "/orico/jellyfin/staging/downloaded-files"
        "/var/backup/postgresql"
      ];
      timerConfig = {
        OnCalendar = restic_backup_time;
        Persistent = true;
      };
    };
    samba = {
      enable = true;
      settings = {
        global = {
          "workgroup" = "BEANTOWN";
          "server string" = "nixnuc";
          "server role" = "standalone server";
          "map to guest" = "never";
          "hosts allow" = "192.168.20.0/22 100.64.0.0/10 127.0.0.1";
          "hosts deny" = "0.0.0.0/0";
          "unix password sync" = "yes";
          "pam password change" = "yes";
          "passwd program" = "/run/wrappers/bin/passwd %u";
        };
        "jellyfin-staging" = {
          path = "/orico/jellyfin/staging";
          "read only" = "no";
          "guest ok" = "no";
          "browseable" = "yes";
          "valid users" = username;
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };
    smartd.enable = true;
    ytdlfin = {
      enable = true;
      user = config.services.jellyfin.user;
      group = config.services.jellyfin.group;
      port = config.dots.ports.ytdlfin.port;
      stagingDir = "/orico/jellyfin/staging/.ytdlfin-staging";
      environmentFile = config.sops.secrets.ytdlfin-env.path;
      settings = {
        oidcIssuerUrl = "https://id.${home_domain}";
        oidcRedirectUri = "https://ytdlfin.${home_domain}/auth/callback";
        oidcAdminGroup = "ytdlfin_admins";
        oidcUserGroup = "ytdlfin_users";
        mediaDirectories = [ "/orico/jellyfin/data" ];
      };
    };
    zfs.autoScrub.enable = true;
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      firefly_app_key = {
        owner = config.services.firefly-iii.user;
        restartUnits = [ "nginx.service" ];
      };
      firefly_pat_data_import = {
        owner = config.services.firefly-iii-data-importer.user;
        restartUnits = [
          "firefly-iii-data-importer-setup.service"
          "phpfpm-firefly-iii-data-importer.service"
        ];
      };
      firefly_simplefin_token = {
        owner = config.services.firefly-iii-data-importer.user;
        restartUnits = [
          "firefly-iii-data-importer-setup.service"
          "phpfpm-firefly-iii-data-importer.service"
        ];
      };
      firefly_vanity_url = {
        owner = config.services.firefly-iii-data-importer.user;
        restartUnits = [
          "firefly-iii-data-importer-setup.service"
          "phpfpm-firefly-iii-data-importer.service"
        ];
      };
      immich_kiosk_basic_auth = {
        owner = config.users.users.nginx.name;
        restartUnits = [ "nginx.service" ];
      };
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
      mealie = {
        mode = "0444";
        restartUnits = [ "mealie.service" ];
      };
      nextcloud_admin_pass.owner = config.users.users.nextcloud.name;
      nginx_basic_auth = {
        owner = "nginx";
        restartUnits = [ "nginx.service" ];
      };
      pocketid_encryption_key = {
        restartUnits = [ "pocket-id.service" ];
      };
      ytdlfin-env = {
        owner = config.services.ytdlfin.user;
        restartUnits = [ config.systemd.services.ytdlfin.name ];
      };
    };
  };

  systemd.services = {
    jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
    "mealie" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
    "nextcloud-setup" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [
      "docker"
      "podman"
      "networkmanager"
      "wheel"
    ];
    linger = true;
  };

  # Enable common container config files in /etc/containers
  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings.engine.database_backend = "sqlite";
    };
    oci-containers.backend = "podman";
    # Compose based apps were crashing with podman compose, so back to Docker...
    docker = {
      enable = true;
      package = pkgs.docker;
    };
    podman = {
      enable = true;
      autoPrune.enable = true;
      #dockerCompat = true;
      extraPackages = [ pkgs.zfs ]; # Required if the host is running ZFS

      # Required for container networking to be able to use names.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
