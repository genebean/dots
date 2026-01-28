{ config, pkgs, ... }: let
  home_domain = "home.technicalissues.us";
in {
  environment.systemPackages = with pkgs; [
    # Keeping empty for manual testing if needed
  ];

  services = {
    # ----------------------------
    # PostgreSQL database
    # ----------------------------
    postgresql = {
      enable = true;
      ensureDatabases = [ "grafana" ];
      ensureUsers = [
        {
          name = "grafana";
          ensureDBOwnership = true;
        }
      ];
    };

    # ----------------------------
    # VictoriaMetrics storage
    # ----------------------------
    victoriametrics = {
      enable = true;
      stateDir = "victoriametrics";  # Just the directory name, module adds /var/lib/ prefix
      package = pkgs.victoriametrics;
    };

    # ----------------------------
    # vmagent: scrape exporters
    # ----------------------------
    vmagent = {
      enable = true;
      package = pkgs.victoriametrics;

      # Prometheus-style scrape configuration
      prometheusConfig = {
        global.scrape_interval = "15s";

        scrape_configs = [
          # Node exporter: CPU, memory, disk, diskio, network, system, ZFS
          {
            job_name = "node";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:9100"      # nixnuc
                  "192.168.22.22:9100"  # home assistant
                  "umbrel:9100"
                ];
              }
            ];
            metric_relabel_configs = [
              {
                source_labels = ["__name__" "nodename"];
                regex = "node_uname_info;0d869efa-prometheus-node-exporter";
                target_label = "nodename";
                replacement = "homeassistant";
              }
              {
                source_labels = ["__name__"];
                regex = "go_.*";
                action = "drop";
              }
            ];
            relabel_configs = [
              {
                target_label = "instance";
                regex = "127.0.0.1.*";
                replacement = "${config.networking.hostName}";
              }
              {
                target_label = "instance";
                regex = "192.168.22.22.*";
                replacement = "homeassistant";
              }
            ];
          }

          # cAdvisor: Docker containers
          {
            job_name = "cadvisor";
            static_configs = [
              { targets = ["127.0.0.1:8081"]; }
            ];
            metric_relabel_configs = [
              {
                source_labels = ["__name__"];
                regex = "go_.*";
                action = "drop";
              }
            ];
            relabel_configs = [
              {
                target_label = "instance";
                replacement = "${config.networking.hostName}";
              }
            ];
          }

          # Nginx exporter
          {
            job_name = "nginx";
            static_configs = [
              { targets = ["127.0.0.1:9113"]; }
            ];
            metric_relabel_configs = [
              {
                source_labels = ["__name__"];
                regex = "go_.*";
                action = "drop";
              }
            ];
            relabel_configs = [
              {
                target_label = "instance";
                replacement = "${config.networking.hostName}";
              }
            ];
          }

          # Home Assistant metrics
          {
            job_name = "homeassistant"; # built in endpoint
            scrape_interval = "30s";
            metrics_path = "/api/prometheus";
            static_configs = [
              { targets = ["192.168.22.22:8123"]; }
            ];
            bearer_token_file = config.sops.secrets.home_assistant_token.path;
            relabel_configs = [
              {
                target_label = "instance";
                replacement = "homeassistant";
              }
            ];
          }

          # Uptime Kuma metrics
          {
            job_name = "uptimekuma";
            scheme = "https";
            scrape_interval = "30s";
            static_configs = [
              { targets = ["utk.technicalissues.us"]; }
            ];
            basic_auth = {
              password_file = config.sops.secrets.uptimekuma_grafana_api_key.path;
              username = "unused";
            };
            metric_relabel_configs = [
              {
                source_labels = ["monitor_hostname"];
                regex = "^null$";
                replacement = "";
                target_label = "monitor_hostname";
              }
              {
                source_labels = ["monitor_port"];
                regex = "^null$";
                replacement = "";
                target_label = "monitor_port";
              }
              {
                source_labels = ["monitor_url"];
                regex = "https:\/\/";
                replacement = "";
                target_label = "monitor_url";
              }
            ];
          }
        ];
      };

      # Remote write to VictoriaMetrics
      remoteWrite.url = "http://127.0.0.1:8428/api/v1/write";

      extraArgs = [
        # Pass other remote write flags the module does not expose natively:
        "-remoteWrite.flushInterval=10s"
        "-remoteWrite.maxDiskUsagePerURL=1GB"

        # Prevent vmagent from failing the entire scrape if a target is down:
        "-promscrape.suppressScrapeErrors"

        # Enable some debugging info suggested by the interface on port 8429
        "-promscrape.dropOriginalLabels=false"
      ];
    };

    # ----------------------------
    # Grafana with VictoriaMetrics datasource
    # ----------------------------
    grafana = {
      enable = true;

      # Install VictoriaMetrics plugin declaratively
      declarativePlugins = [
        pkgs.grafanaPlugins.victoriametrics-metrics-datasource
      ];

      provision = {
        # Alert rules provisioning
        # To add more rules: create them in Grafana UI, then export via:
        # Alerting -> Alert rules -> Export rules (YAML format)
        # Copy the exported rules into ./alert-rules.nix
        alerting.rules.path = ./grafana-files/alert-rules.yaml;

        datasources.settings.datasources = [
          {
            name   = "VictoriaMetrics";
            type   = "victoriametrics-metrics-datasource";
            access = "proxy";
            url    = "http://127.0.0.1:8428";
            isDefault = true;
            uid = "VictoriaMetrics";  # Set explicit UID for use in alert rules
          }
        ];
      };


      settings = {
        auth = {
          # Set to true to disable (hide) the login form, useful if you use OAuth
          disable_login_form = false;
        };

        "auth.generic_oauth" = {
          name                       = "Pocket ID";
          enabled                    = true;

          # Use Grafana's file reference syntax for secrets
          client_id                  = "$__file{${config.sops.secrets.grafana_oauth_client_id.path}}";
          client_secret              = "$__file{${config.sops.secrets.grafana_oauth_client_secret.path}}";

          auth_style                 = "AutoDetect";
          scopes                     = "openid email profile groups";
          auth_url                   = "${config.services.pocket-id.settings.APP_URL}/authorize";
          token_url                  = "${config.services.pocket-id.settings.APP_URL}/api/oidc/token";
          allow_sign_up              = true;
          auto_login                 = true;
          name_attribute_path        = "display_name";
          login_attribute_path       = "preferred_username";
          email_attribute_name       = "email:primary";
          email_attribute_path       = "email";
          role_attribute_path        = "contains(groups[*], 'grafana_super_admin') && 'GrafanaAdmin' || contains(groups[*], 'grafana_admin') && 'Admin' || contains(groups[*], 'grafana_editor') && 'Editor' || 'Viewer'";
          role_attribute_strict      = false;
          allow_assign_grafana_admin = true;
          skip_org_role_sync         = false;
          use_pkce                   = true;
          use_refresh_token          = false;
          tls_skip_verify_insecure   = false;
        };

        # Database configuration - use PostgreSQL with peer authentication
        database = {
          type = "postgres";
          host = "/run/postgresql";  # Use Unix socket instead of TCP
          name = "grafana";
          user = "grafana";
          # No password needed - using peer authentication via Unix socket
        };

        # Server configuration
        server = {
          domain             = "monitoring.${home_domain}";
          http_addr          = "0.0.0.0";
          http_port          = 3002;
          root_url           = "https://monitoring.${home_domain}/grafana/";
          serve_from_sub_path = true;
        };

        # Enable unified alerting (Grafana's built-in alerting)
        "unified_alerting" = {
          enabled = true;
        };

        # Disable legacy alerting
        alerting.enabled = false;
      };
    };

    # ----------------------------
    # Exporters (using built-in NixOS modules)
    # ----------------------------
    
    # Node exporter - using the built-in module
    prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
      enabledCollectors = [
        "zfs"
        "systemd"
      ];
      extraFlags = [
        "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|run|tmp|var/lib/docker/.+)($|/)"
        "--collector.diskstats.device-exclude=^(loop|ram|fd|sr|dm-|nvme[0-9]n[0-9]p[0-9]+_crypt)$"
      ];
    };

    # Nginx exporter - using the built-in module
    prometheus.exporters.nginx = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9113;
      scrapeUri = "https://127.0.0.1/server_status";
      sslVerify = false;
    };

    # cAdvisor for Docker containers
    cadvisor = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 8081;
      extraOptions = [
        "--docker_only=true"
        "--housekeeping_interval=30s"
        "--disable_metrics=hugetlb"
      ];
    };
  };

  # ----------------------------
  # Users and groups for service accounts
  # ----------------------------
  users.users.vmagent = {
    isSystemUser = true;
    group = "vmagent";
  };

  users.groups.vmagent = {};

  # ----------------------------
  # Systemd service dependencies
  # ----------------------------
  systemd.services.grafana = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };

  # ----------------------------
  # SOPS secrets configuration
  # ----------------------------
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      grafana_oauth_client_id = {
        owner = "grafana";
        restartUnits = ["grafana.service"];
      };
      grafana_oauth_client_secret = {
        owner = "grafana";
        restartUnits = ["grafana.service"];
      };
      home_assistant_token = {
        owner = "vmagent";
        restartUnits = ["vmagent.service"];
      };
      uptimekuma_grafana_api_key = {
        owner = "vmagent";
        restartUnits = ["vmagent.service"];
        sopsFile = ../../common/secrets.yaml;
      };
    };
  };

  # -----------------------------
  # Backups of all this
  # -----------------------------
  services.restic.backups.daily = {
    paths = [
      config.services.grafana.dataDir
      config.services.victoriametrics.stateDir
    ];
  };
}

