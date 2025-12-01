{ config, lib, pkgs, username, ... }: let
  domain = "technicalissues.us";
  restic_backup_time = "01:00";
in {
  imports = [
    ../../../common/linux/lets-encrypt.nix
    ../../../common/linux/restic.nix
    ./containers/emqx.nix
    ./matrix-synapse.nix
    #./mosquitto.nix
    ./nginx.nix
  ];

  mailserver = {
    enable = true;
    enableImap = false;
    enableImapSsl = true;
    enableSubmission = false;
    enableSubmissionSsl = true;
    fqdn = "mail.alt.${domain}";
    domains = [
      "alt.${domain}"
      "indianspringsbsa.org"
      "pack1828.org"
    ];
    stateVersion = 3;

    # Use Let's Encrypt certificates from Nginx
    certificateScheme = "acme";
  };

  services = {
    collabora-online = {
      enable = true;
      port = 9980; # default
      settings = {
        # Rely on reverse proxy for SSL
        ssl = {
          enable = false;
          termination = true;
        };

        # Listen on loopback interface only, and accept requests from ::1
        net = {
          listen = "loopback";
          post_allow.host = ["::1"];
        };

        # Restrict loading documents from WOPI Host nextcloud.example.com
        storage.wopi = {
          "@allow" = true;
          host = [ "https://cloud.pack1828.org" ];
        };

        # Set FQDN of server
        server_name = "collabora.pack1828.org";
      };
    };
    nextcloud = {
      enable = true;
      hostName = "cloud.pack1828.org";
      package = pkgs.nextcloud31; # Need to manually increment with every major upgrade.
      appstoreEnable = true;
      autoUpdateApps.enable = true;
      config = {
        adminuser = username;
        adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
        dbtype = "pgsql";
      };
      configureRedis = true;
      database.createLocally = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        # List of apps we want to install and are already packaged in
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit
          richdocuments # Collabora Online for Nextcloud - https://apps.nextcloud.com/apps/richdocuments
          ;
      };
      extraAppsEnable = true;
      home = "/pack1828/nextcloud";
      https = true;
      maxUploadSize = "3G"; # Increase the PHP maximum file upload size
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
    plausible = {
      enable = true;
      database = {
        clickhouse.setup = true;
        postgres.setup = true;
      };
      mail.email = "stats@${domain}";
      server = {
        baseUrl = "https://stats.${domain}";
        disableRegistration = true;
        port = 8001;
        # secretKeybaseFile is a path to the file which contains the secret generated
        # with openssl as described above.
        secretKeybaseFile = config.sops.secrets.plausible_secret_key_base.path;
      };
    };
    restic.backups.daily = {
      paths = [
        "${config.users.users.${username}.home}/compose-files/owntracks"
        "/var/backup/postgresql"
        "/var/lib/uptime-kuma"
      ];
      timerConfig = {
        OnCalendar = restic_backup_time;
        Persistent = true;
      };
    };
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
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets.yaml;
    secrets = {
      local_git_config = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.gitconfig-local";
      };
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
      matrix_secrets_yaml = {
        owner = config.users.users.matrix-synapse.name;
        restartUnits = ["matrix-synapse.service"];
      };
      matrix_homeserver_signing_key.owner = config.users.users.matrix-synapse.name;
      mqtt_recorder_pass.restartUnits = ["mosquitto.service"];
      nextcloud_admin_pass.owner = config.users.users.nextcloud.name;
      owntracks_basic_auth = {
        owner = config.users.users.nginx.name;
        restartUnits = ["nginx.service"];
      };
      plausible_admin_pass.owner = config.users.users.nginx.name;
      plausible_secret_key_base.owner = config.users.users.nginx.name;
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  };

  systemd.services = {
    nextcloud-config-collabora = let
      inherit (config.services.nextcloud) occ;

      wopi_url = "http://[::1]:${toString config.services.collabora-online.port}";
      public_wopi_url = "https://collabora.pack1828.org";
      wopi_allowlist = lib.concatStringsSep "," [
        "127.0.0.1"
        "::1"
        "5.161.244.95"
        "2a01:4ff:f0:977c::1"
      ];
    in {
      wantedBy = ["multi-user.target"];
      after = ["nextcloud-setup.service" "coolwsd.service"];
      requires = ["coolwsd.service"];
      script = ''
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
        ${occ}/bin/nextcloud-occ richdocuments:setup
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
