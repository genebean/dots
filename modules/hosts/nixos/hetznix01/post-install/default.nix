{ config, pkgs, username, ... }: let
  domain = "technicalissues.us";
in {
  imports = [
    ../../../common/linux/lets-encrypt.nix
    ../../../common/linux/restic.nix
    ./matrix-synapse.nix
    ./nginx.nix
  ];

  mailserver = {
    enable = true;
    enableImap = false;
    enableImapSsl = false;
    fqdn = "mail.alt.${domain}";
    domains = [
      "alt.${domain}"
      "indianspringsbsa.org"
    ];
    forwards = {
      "webmaster@indianspringsbsa.org" = "gene+indianspringsbsa.org@geneliverman.com";
      "newsletter@indianspringsbsa.org" = "gene+indianspringsbsa.org@geneliverman.com";
      "@alt.${domain}" = "gene+alt.${domain}@geneliverman.com";
      "${username}@localhost" = "${username}@technicalissues.us";
      "root@localhost" = "root@technicalissues.us";
      "root@${config.networking.hostName}" = "root@technicalissues.us";
    };

    # Use Let's Encrypt certificates from Nginx
    certificateScheme = "acme";
  };

  services = {
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
      #extraApps = with config.services.nextcloud.package.packages.apps; {
      #  # List of apps we want to install and are already packaged in
      #  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
      #  inherit calendar contacts cookbook maps notes tasks;
      #};
      #extraAppsEnable = true;
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
      adminUser = {
        # activate is used to skip the email verification of the admin-user that's
        # automatically created by plausible. This is only supported if
        # postgresql is configured by the module. This is done by default, but
        # can be turned off with services.plausible.database.postgres.setup.
        activate = true;
        email = "${username}@technicalissues.us";
        name = username;
        passwordFile = config.sops.secrets.plausible_admin_pass.path;
      };
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
    restic.backups.daily.paths = [
      "${config.users.users.${username}.home}/compose-files/owntracks"
      "/var/backup/postgresql"
      "/var/lib/uptime-kuma"
    ];
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
