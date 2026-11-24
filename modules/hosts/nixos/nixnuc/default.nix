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
    ./attic.nix
    ./containers/audiobookshelf.nix
    ./containers/bead-me-up-scotty.nix
    ./containers/buzz.nix
    ./containers/gitdeck.nix
    ./containers/mountain-mesh-bot-discord.nix
    ./containers/photon.nix
    ./containers/psitransfer.nix
    ./containers/rustfs.nix
    ./cup-collector.nix
    ./dolt-beads-server.nix
    ./filtered-podcast-feeds.nix
    ./forgejo.nix
    ./karakeep.nix
    ./monitoring-stack.nix
    ./newspaper.nix
    ./ports.nix
    ./social-reader-mcp.nix
    ./zfs-datasets.nix
    ../../../shared/nixos/auditd.nix
    # Still needed here: cup-collector.nix and dolt-beads-server.nix each
    # issue their own direct ACME cert (not via nginx at all), relying on
    # this module's security.acme.defaults. Only the nginx-fronted public
    # vhosts' ACME moved to pigate - crowdsec.nix and fail2ban-nginx.nix
    # did NOT come back, since those existed only to protect a publicly-
    # reachable nginx, which this host no longer has.
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
    # http/https stay openFirewall=true fleet-wide (modules/genebean/nixos/
    # ports.nix) even though the public, internet-facing vhosts all moved
    # to pigate - nginx's main listener on this host now binds only to the
    # services-VLAN IP, so the open 80/443 here is inert. Not worth
    # overriding the shared default just for this. social-reader-mcp-https
    # below is the one exception still bound to 0.0.0.0, same as before
    # this whole migration - it was never part of pigate's internet-facing
    # attack surface to begin with (see ports.nix).
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

    # nginx (and the SNI-on-loopback problem it caused for same-host
    # callers) moved to pigate - the attic.*/id.* workaround entries that
    # used to live here no longer apply.
    extraHosts = ''
      # dolt-beads terminates TLS itself directly (one cert, no nginx/SNI
      # involved), so same-host callers like Scotty can safely go straight
      # to loopback instead of hairpinning out through the LAN IP for a
      # local connection.
      127.0.0.1 dolt-beads.home.technicalissues.us
    '';

    hostId = "c5826b45"; # head -c4 /dev/urandom | od -A none -t x4

    useDHCP = false;
    networkmanager.enable = false;
    useNetworkd = true;
    # "services" zone for pigate (the DMZ reverse-proxy host) to reach this
    # host's backend apps - replaces an earlier, abandoned vlan23 attempt
    # that used this same 192.168.23.x address space for something else.
    vlans = {
      vlan2332 = {
        id = 2332;
        interface = "eno1";
      };
    };
    interfaces = {
      eno1.useDHCP = true;
      vlan2332.ipv4 = {
        addresses = [
          {
            address = "192.168.23.130";
            prefixLength = 25;
          }
        ];
        # Explicit route for the wider 192.168.23.0/24 block via this
        # VLAN's gateway, not just pigate's own /30 - without it, replies
        # to pigate (or anything else later carved out of this same /24)
        # would go out this host's main LAN default route instead, an
        # asymmetric path the UniFi's stateful zone firewall would drop as
        # an unrecognized return packet.
        routes = [
          {
            address = "192.168.23.0";
            prefixLength = 24;
            via = "192.168.23.129";
          }
        ];
      };
    };
  };

  # Enable sound with pipewire.
  security.rtkit.enable = true;

  programs = {
    mtr.enable = true;
  };

  genebean.services.dnclient.enable = true;
  # Public GitHub OAuth App Client ID. The access token stays in Gitdeck's
  # persistent data volume after Device Flow sign-in.
  genebean.gitdeck.githubClientId = "Iv23liyEFHlh7RaanbfK";

  # List services that you want to enable:
  services = {
    atuin = {
      enable = true;
      # All interfaces, matching the rest of the fleet's internal-only
      # services (and attic.nix's same fix) - nginx moved to pigate,
      # reaching this over the services VLAN instead of loopback.
      host = "0.0.0.0";
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
    # Trimmed to exactly the vhosts that either can't become a plain
    # proxy_pass from pigate to an app port, or never belonged on the DMZ
    # edge in the first place:
    #   - nextcloud: services.nextcloud.nginx assumes a co-located php-fpm
    #     socket.
    #   - newspaper: oauth2-proxy's own nginx integration injects
    #     auth_request config into a vhost on this same host (newspaper.nix).
    #   - podcasts: serves static files straight off this host's local disk.
    #   - social-reader-mcp: LAN-only, IP-restricted to tcan-left, never
    #     internet-facing - no reason to route it through pigate at all.
    # The first three are plain HTTP on the services-VLAN IP only, since
    # pigate already terminated client-facing TLS before that hop.
    # social-reader-mcp keeps its own direct ACME/SSL on 0.0.0.0, exactly
    # as before this migration - hence recommendedTlsSettings staying on
    # below. Every other public vhost (the TLS-terminating, ACME-covered,
    # CrowdSec/fail2ban-protected ones) now lives on pigate instead.
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true; # needed for social-reader-mcp's own ACME/SSL vhost below
      appendHttpConfig = ''
        # pigate is the only path into this nginx (see
        # modules/hosts/nixos/pigate/default.nix's proxy_pass to
        # ${backend_ip}:80) - trust its X-Forwarded-For so $remote_addr
        # here reflects the real client, not pigate itself. Without this,
        # every request would appear to originate from pigate: Nextcloud's
        # own access log (and the nextcloud fail2ban jail above, which
        # greps that log for remoteAddr) would never see the real
        # attacker, and could end up trying to ban pigate instead.
        set_real_ip_from 192.168.23.2;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;
      '';
      virtualHosts = {
        "nextcloud.${home_domain}" = {
          listen = [
            {
              addr = "192.168.23.130";
              port = 80;
            }
          ];
        };
        "newspaper.${home_domain}" = {
          listen = [
            {
              addr = "192.168.23.130";
              port = 80;
            }
          ];
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
        "podcasts.${home_domain}" = {
          listen = [
            {
              addr = "192.168.23.130";
              port = 80;
            }
          ];
          basicAuthFile = config.sops.secrets.filtered_podcast_feeds_basic_auth.path;
          locations."/feeds/" = {
            alias = "/var/lib/filtered-podcast-feeds/";
            extraConfig = ''
              default_type application/rss+xml;
              add_header Cache-Control "public, max-age=300";
            '';
          };
        };
        # hermes-agent-fleet-plan issue 37: Danny's only path to
        # social-reader-mcp. Its own dedicated port (not the shared
        # genebean.ports.https listener other vhosts used to use) - the
        # firewall rule above restricts TCP/8443 to tcan-left specifically,
        # and mixing that with the fleet-wide-reachable 443 vhosts would
        # make the restriction easy to lose track of later. Stays on this
        # host, not pigate - it's LAN-only by design, never part of the
        # internet-facing surface pigate exists to protect.
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
      # Peer-authenticated (no password - see attic.nix's database.url),
      # matching the default "local all all peer" pg_hba rule. atticd
      # connects over the unix socket as its own OS user, which NixOS's
      # ensureUsers never deletes if this is removed later.
      ensureUsers = [ { name = "atticd"; } ];
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
        "/orico/immich/library"
        "/orico/jellyfin/data"
        "/orico/jellyfin/staging/downloaded-files"
        "/var/backup/dolt-beads"
        "/var/backup/postgresql"
        "/var/lib/gitdeck/data"
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
      attic_rs256_secret = {
        restartUnits = [ "atticd.service" ];
      };
      # sopsFile for this comes from lets-encrypt.nix (still imported here
      # for cup-collector.nix/dolt-beads-server.nix's own direct ACME
      # certs) - just adding ddclient to the restart list.
      gandi_dns_pat.restartUnits = [ "ddclient.service" ];
      karakeep_env = {
        owner = "karakeep";
        restartUnits = [
          "karakeep-web.service"
          "karakeep-workers.service"
        ];
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
    # Attic's dedicated tablespace (attic.nix) needs to exist, owned by
    # postgres, before Postgres starts. Confirmed live: an ExecStartPre on
    # postgresql.service itself does NOT work for this, even "+"-prefixed -
    # systemd builds a unit's ReadWritePaths bind-mounts as part of
    # constructing its namespace, which happens before ANY ExecStartPre
    # runs, so a path that only gets created by that same unit's own
    # ExecStartPre can never exist in time. This crashed postgresql.service
    # itself (226/NAMESPACE, then start-limit-hit) and took Nextcloud's
    # update-db check down with it. systemd.tmpfiles.rules runs as its own
    # independent step (systemd-tmpfiles-setup.service, reprocessed on
    # every activation), fully outside postgresql.service's namespace, so
    # the directory already exists by the time ReadWritePaths needs it.
    postgresql = {
      after = [
        "attic.mount"
        "systemd-tmpfiles-setup.service"
      ];
      requires = [ "attic.mount" ];
      serviceConfig.ReadWritePaths = [ "/attic/postgresql-tablespace" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /attic/postgresql-tablespace 0700 postgres postgres - -"
  ];

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
