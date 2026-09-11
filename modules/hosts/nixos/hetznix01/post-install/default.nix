{
  config,
  pkgs,
  username,
  ...
}:
let
  domain = "technicalissues.us";
  restic_backup_time = "01:00";
in
{
  imports = [
    ../../../../shared/nixos/lets-encrypt.nix
    ./containers/emqx.nix
    ./matrix-synapse.nix
    ./monitoring.nix
    #./mosquitto.nix
    ./nginx.nix
    ./wordpress.nix
  ];

  services = {
    clickhouse.serverConfig = {
      # pulled in by plausible
      trace_log.ttl = "event_date + INTERVAL 14 DAY DELETE";
      metric_log.ttl = "event_date + INTERVAL 14 DAY DELETE";
      asynchronous_metric_log.ttl = "event_date + INTERVAL 14 DAY DELETE";
      part_log.ttl = "event_date + INTERVAL 30 DAY DELETE";
      query_log.ttl = "event_date + INTERVAL 30 DAY DELETE";
      query_thread_log.ttl = "event_date + INTERVAL 30 DAY DELETE";
      text_log.ttl = "event_date + INTERVAL 14 DAY DELETE";
    };
    dawarich = {
      enable = true;
      configureNginx = true;
      environment = {
        PHOTON_API_HOST = "nixnuc.${config.private-flake.tailnetDomain}:${toString config.genebean.ports.photon.port}";
        PHOTON_API_USE_HTTPS = "false";
      };
      extraEnvFiles = [
        "${config.sops.secrets.dawarich_env.path}"
      ];
      localDomain = "location.technicalissues.us";
      smtp = {
        fromAddress = "location@hetznix01.technicalissues.us";
        host = "127.0.0.1";
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
        inherit (config.genebean.ports.plausible) port;
        # secretKeybaseFile is a path to the file which contains the secret generated
        # with openssl as described above.
        secretKeybaseFile = config.sops.secrets.plausible_secret_key_base.path;
      };
    };
    restic.backups.daily = {
      paths = [
        "/var/backup/postgresql"
        "/var/lib/uptime-kuma"
      ];
      timerConfig = {
        OnCalendar = restic_backup_time;
        Persistent = true;
      };
    };
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets.yaml;
    secrets = {
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
      dawarich_env = {
        owner = config.services.dawarich.user;
        restartUnits = [ "dawarich-web.service" ];
      };
      matrix_secrets_yaml = {
        owner = config.users.users.matrix-synapse.name;
        restartUnits = [ "matrix-synapse.service" ];
      };
      matrix_homeserver_signing_key.owner = config.users.users.matrix-synapse.name;
      mqtt_recorder_pass.restartUnits = [ "mosquitto.service" ];
      plausible_admin_pass.owner = config.users.users.nginx.name;
      plausible_secret_key_base.owner = config.users.users.nginx.name;
    };
  };

  systemd = {
    services = {
      clickhouse-drop-orphaned-logs = {
        description = "Drop orphaned numbered ClickHouse system log tables";
        after = [ "clickhouse.service" ];
        requires = [ "clickhouse.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.clickhouse}/bin/clickhouse-client \
            --query "SELECT concat('DROP TABLE IF EXISTS system.', name, ';') \
                     FROM system.tables \
                     WHERE database = 'system' \
                     AND match(name, '^[a-z_]+_log_[0-9]+')" \
            | ${pkgs.clickhouse}/bin/clickhouse-client --multiquery
        '';
      };

    };

    timers.clickhouse-drop-orphaned-logs = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "monthly";
        Persistent = true;
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
