{ config, pkgs, ... }: let
  metrics_server = "https://monitoring.home.technicalissues.us/remotewrite";
in {
  services = {
    vmagent = {
      enable = true;
      package = pkgs.victoriametrics;

      # Prometheus-style scrape configuration
      prometheusConfig = {
        global.scrape_interval = "15s";

        scrape_configs = [
          {
            job_name = "node";
            static_configs = [
              { targets = ["127.0.0.1:9100"]; }
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
                regex = "127.0.0.1.*";
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
        ];
      };

      # Remote write to VictoriaMetrics
      remoteWrite = {
        basicAuthUsername = "metricsshipper";
        basicAuthPasswordFile = config.sops.secrets.vmagent_push_pw.path;
        url = metrics_server;
      };

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
    # Exporters (using built-in NixOS modules)
    # ----------------------------
    
    # Node exporter - using the built-in module
    prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
      enabledCollectors = [
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
  # SOPS secrets configuration
  # ----------------------------
  sops = {
    secrets = {
      vmagent_push_pw = {
        owner = "vmagent";
        restartUnits = ["vmagent.service"];
        sopsFile = ../../../common/secrets.yaml;
      };
    };
  };
}

