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
    ./containers/bead-me-up-scotty.nix
    ./containers/buzz.nix
    ./containers/mountain-mesh-bot-discord.nix
    ./containers/photon.nix
    ./containers/psitransfer.nix
    ./containers/rustfs.nix
    ./cup-collector.nix
    ./dolt-beads-server.nix
    ./filtered-podcast-feeds.nix
    ./forgejo.nix
    ./monitoring-stack.nix
    ./newspaper.nix
    ./ports.nix
    ./social-reader-mcp.nix
    ./zfs-datasets.nix
    ../../../shared/nixos/auditd.nix
    ../../../shared/nixos/crowdsec.nix
    ../../../shared/nixos/fail2ban-nginx.nix
    ../../../shared/nixos/lets-encrypt.nix
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
    etc = {
      # Neither Nextcloud nor Jellyfin ships a fail2ban filter, unlike
      # nginx/postfix/dovecot (bundled with the fail2ban package itself) or
      # WordPress (ships its own via the wp-fail2ban plugin, see
      # hetznix01/post-install/wordpress.nix). These two are hand-written,
      # and were validated live on 2026-10-23 (not just eyeballed): a real
      # failed login was deliberately triggered against each app and
      # `fail2ban-regex` confirmed a match against the live log line below.
      # That same check is what caught the live jails silently running
      # under the systemd/journal backend instead of actually reading
      # logpath (see backend = polling on each jail, below).
      "fail2ban/filter.d/nextcloud.conf".text = ''
        # Matches Nextcloud's JSON log format (log_type = "file", set in
        # services.nextcloud.settings below) - widely-used community
        # pattern, not an officially bundled fail2ban filter. Confirmed
        # live against: {"reqId":"...","remoteAddr":"1.2.3.4",...,
        # "message":"Login failed: 'user' (Remote IP: '1.2.3.4')",...}
        [Definition]
        failregex = ,"remoteAddr":"<HOST>".*Login failed:
      '';
      "fail2ban/filter.d/jellyfin.conf".text = ''
        # Pattern published by Jellyfin's own docs (jellyfin.org/docs/general/
        # post-install/networking/advanced/fail2ban/). No manual Log Level
        # step needed, unlike what those docs assume - confirmed live that
        # this Jellyfin version already defaults to "Information" (no
        # logging.json override present, only the stock logging.default.json
        # which already sets MinimumLevel.Default to "Information").
        [Definition]
        failregex = ^.*Authentication request for .* has been denied \(IP: "<HOST>"\)\.$
      '';
    };
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
  #
  # Dropped intel-ocl (legacy Intel SRB5.0 OpenCL SDK): this host's CPU is a
  # 6th-gen Skylake i7-6770HQ, already covered by intel-compute-runtime-legacy1
  # (NEO, "pre-13th gen cpu") - intel-ocl only matters for older iGPUs NEO
  # doesn't support. Confirmed on the live host that neither package is
  # currently exercised anyway: Jellyfin's own encoding.xml has
  # HardwareAccelerationType=none (pure software transcoding), and
  # /etc/OpenCL/vendors/ doesn't exist at all. Its upstream fetchurl source
  # (both the primary mirror and the web.archive.org fallback) started
  # returning 403 and broke CI - removed rather than patched since it was
  # never load-bearing for this hardware to begin with.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime-legacy1 # pre-13th gen cpu
      intel-media-driver # For Broadwell and newer (ca. 2014+), use with LIBVA_DRIVER_NAME=iHD:
    ];
  };

  networking = {
    firewall = {
      allowedTCPPorts = lib.pipe config.genebean.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "tcp"))
        (map (e: e.port))
      ];
      allowedUDPPorts = lib.pipe config.genebean.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "udp"))
        (map (e: e.port))
      ];

      # hermes-agent-fleet-plan issue 37: social-reader-mcp-https (8443) is
      # deliberately NOT in genebean.ports' openFirewall allowlist above -
      # that would open it fleet-wide. Only tcan-left (Danny's host) may
      # reach it; everyone else falls through to nixos-fw's normal default
      # reject, same as any other unlisted port. See dots#760 for making
      # this a reusable genebean.ports option once there's a second case.
      extraCommands = ''
        iptables -A nixos-fw -p tcp -s 192.168.20.191 --dport ${toString config.genebean.ports.social-reader-mcp-https.port} -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p tcp -s 192.168.20.191 --dport ${toString config.genebean.ports.social-reader-mcp-https.port} -j nixos-fw-accept || true
      '';
    };

    # oauth2-proxy's OIDC discovery call (newspaper.nix) was hitting
    # PocketID via its public hostname despite both running on this same
    # host - fine most of the time via hairpin NAT, but not guaranteed, and
    # unnecessary for a same-host call. Pin it to this host's own LAN IP
    # instead of 127.0.0.1 - confirmed live that nginx does NOT route SNI
    # correctly on loopback (serves the wrong vhost's cert, breaking TLS
    # verification entirely), but the LAN IP is the same path every real
    # client already uses successfully.
    extraHosts = ''
      192.168.20.190 id.home.technicalissues.us
      # dolt-beads terminates TLS itself directly (one cert, no nginx/SNI
      # involved - unlike id.home.technicalissues.us above), so same-host
      # callers like Scotty can safely go straight to loopback instead of
      # hairpinning out through the LAN IP for a local connection.
      127.0.0.1 dolt-beads.home.technicalissues.us
    '';

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

  genebean.services.dnclient.enable = true;

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
    fail2ban = {
      # sshd jail comes enabled by default from the fail2ban package itself;
      # nginx-http-auth/nginx-botsearch jails come from
      # ../../../shared/nixos/fail2ban-nginx.nix (imported above). The two
      # below use the hand-written filters in environment.etc above - see
      # the comments there. Both validated live (2026-10-23): deliberately
      # triggered a real failed login against each app, confirmed the
      # resulting log line with `fail2ban-regex`, THEN found the live jails
      # were silently running under fail2ban's systemd/journal backend
      # instead of reading logpath at all ("Currently failed: 0" despite a
      # confirmed regex match) - fail2ban's "auto" backend prefers systemd
      # whenever it's available, regardless of logpath being set. backend
      # = polling below forces it to actually tail the file.
      enable = true;
      jails = {
        "nextcloud" = ''
          enabled  = true
          filter   = nextcloud
          backend  = polling
          # Confirmed via live deploy, not guessed from datadir: the real
          # file is under data/, not directly in datadir.
          logpath  = /orico/nextcloud/data/nextcloud.log
          maxretry = 5
          findtime = 600
          bantime  = 3600
        '';
        "jellyfin" = ''
          enabled  = true
          filter   = jellyfin
          backend  = polling
          logpath  = /var/lib/jellyfin/log/*.log
          maxretry = 5
          findtime = 600
          bantime  = 3600
        '';
      };
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
      inherit (config.genebean.ports.mealie) port;
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
      package = pkgs.nextcloud34; # Need to manually increment with every major upgrade.
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

        # Mealie has no built-in rate limiting at all on its API (confirmed
        # from Mealie's own security docs, which explicitly recommend doing
        # this at the reverse proxy) - no fail2ban filter needed/available,
        # this covers the same ground at the nginx layer instead.
        limit_req_zone $binary_remote_addr zone=mealie_login:1m rate=10r/m;
      '';
      virtualHosts = {
        "${home_domain}" = {
          default = true;
          serverAliases = [
            "nix-tester.${home_domain}"
          ];
          listen = [
            {
              inherit (config.genebean.ports.https) port;
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
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyWebsockets = true;
          locations."/".proxyPass =
            "http://${backend_ip}:${toString config.genebean.ports.audiobookshelf.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "atuin.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.atuin.port}";
        };
        "buzz.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.buzz-relay.port}";
              proxyWebsockets = true;
            };
            # Device pairing (NIP-AB): a separate binary/process from the main
            # relay (buzz.nix's buzz-pair-relay container), not buzz-relay
            # itself. Desktop/mobile clients derive this path from the main
            # relay's own NIP-11 supported_nips list advertising 43.
            "/pair" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.buzz-pair-relay.port}";
              proxyWebsockets = true;
            };
          };
        };
        "git.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.forgejo.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "id.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.pocket-id.port}";
          extraConfig = ''
            proxy_busy_buffers_size   512k;
            proxy_buffers           4 512k;
            proxy_buffer_size         256k;
          '';
        };
        "immich.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.immich.port}";
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
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          basicAuthFile = config.sops.secrets.immich_kiosk_basic_auth.path;
          locations."/".proxyPass =
            "http://${backend_ip}:${toString config.genebean.ports.immich-kiosk.port}";
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
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.jellyfin.port}";
              extraConfig = ''
                proxy_buffering off;
                proxy_set_header X-Forwarded-Protocol $scheme;
              '';
            };
            "/socket" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.jellyfin.port}";
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
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.mealie.port}";
            "= /api/auth/token" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.mealie.port}/api/auth/token";
              extraConfig = ''
                limit_req zone=mealie_login burst=3 nodelay;
              '';
            };
          };
          extraConfig = ''
            client_max_body_size 10M;
          '';
        };
        "monitoring.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/grafana/".proxyPass =
              "http://${backend_ip}:${toString config.genebean.ports.grafana.port}/grafana/";
            "/remotewrite" = {
              basicAuthFile = config.sops.secrets.nginx_basic_auth.path;
              proxyPass = "http://127.0.0.1:${toString config.genebean.ports.victoriametrics.port}/api/v1/write";
              proxyWebsockets = true;
            };
          };
        };
        "newspaper.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            # `satisfy any;` - either passes: basicAuthFile (Hermes agents,
            # which can't do an interactive OIDC login) OR the PocketID
            # auth_request that services.oauth2-proxy.nginx injects at the
            # vhost level (humans, restricted to the "beantown_subscribers"
            # group - see newspaper.nix). Without this the two would stack
            # as a requirement, not an alternative.
            "/" = {
              basicAuthFile = config.sops.secrets.newspaper_basic_auth.path;
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.newspaper.port}";
              extraConfig = ''
                satisfy any;
              '';
            };
            # Exempt from the vhost-wide auth_request PocketID gating adds -
            # this already has its own bearer-token check (X-Deploy-Token),
            # and either a basic-auth prompt or an OIDC redirect here would
            # break the automated POST from the publish workflow.
            "/hooks/" = {
              proxyPass = "http://127.0.0.1:${toString config.genebean.ports.newspaper-webhook.port}/hooks/";
              extraConfig = ''
                auth_request off;
              '';
            };
          };
        };
        "nextcloud.${home_domain}" = {
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
        };
        "podcasts.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          basicAuthFile = config.sops.secrets.filtered_podcast_feeds_basic_auth.path;
          locations."/feeds/" = {
            alias = "/var/lib/filtered-podcast-feeds/";
            extraConfig = ''
              default_type application/rss+xml;
              add_header Cache-Control "public, max-age=300";
            '';
          };
        };
        # Wallabag taken off the internet (2026-10-21): its Docker Hub image
        # hasn't been rebuilt since 2025-10-07 and still ships EOL PHP 8.1.32,
        # which has no fix coming for the php2shell RCEs (CVE-2026-109618 /
        # CVE-2026-109619) - genebean/dots#685 tracks the Karakeep migration
        # that replaces it. Still reachable on the LAN at
        # http://<nixnuc-lan-ip>:${toString config.genebean.ports.wallabag.port}
        # in the meantime.
        # "readit.${home_domain}" = {
        #   listen = [
        #     {
        #       inherit (config.genebean.ports.https) port;
        #       addr = "0.0.0.0";
        #       ssl = true;
        #     }
        #   ];
        #   enableACME = true;
        #   acmeRoot = null;
        #   forceSSL = true;
        #   locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.wallabag.port}";
        # };
        # hermes-agent-fleet-plan issue 37: Danny's only path to
        # social-reader-mcp. Its own dedicated port (not the shared
        # genebean.ports.https listener other vhosts use) - the firewall
        # rule below restricts TCP/8443 to tcan-left specifically, and
        # mixing that with the fleet-wide-reachable 443 vhosts would make
        # the restriction easy to lose track of later.
        "social-reader-mcp.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.social-reader-mcp-https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/mcp".proxyPass =
            "http://${backend_ip}:${toString config.genebean.ports.social-reader-mcp.port}/mcp";
        };
        "ytdlfin.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.ytdlfin.port}";
          locations."= /health" = {
            proxyPass = "http://${backend_ip}:${toString config.genebean.ports.ytdlfin.port}";
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
        config.services.mealie.settings.DATA_DIR
        config.services.nextcloud.home
        "${config.users.users.${username}.home}/compose-files/wallabag"
        "/orico/immich/library"
        "/orico/jellyfin/data"
        "/orico/jellyfin/staging/downloaded-files"
        "/var/backup/dolt-beads"
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
      port = config.genebean.ports.ytdlfin.port;
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
