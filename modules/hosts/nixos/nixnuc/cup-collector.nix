{
  inputs,
  config,
  pkgs,
  ...
}:
let
  home_domain = "home.technicalissues.us";
in
{
  services = {
    cupCollector = {
      enable = true;
      # dataDir = "/var/lib/cup-collector";
      domain = "cups.${home_domain}";
      envFile = config.sops.secrets.cup_collector_env.path;
      households = [
        {
          name = "Liverman Family";
          slug = "liverman_family";
        }
      ];
      migrationsDir = inputs.cup-collector.packages.${pkgs.stdenv.hostPlatform.system}.migrations;
      pbBindIp = "0.0.0.0";
      pbPort = config.genebean.ports.pocketbase.port; # override default due to conflict
      pocketidIssuerUrl = config.services.pocket-id.settings.APP_URL;
      inherit (config.genebean.ports.cup-collector) port; # override default due to conflict
    };

    restic.backups.daily = {
      paths = [
        config.services.cupCollector.dataDir
      ];
    };

    # http2 = false: see the stopgap comment above default.nix's nginx
    # virtualHosts block (CVE-2026-123633 / CVE-2026-123007). cupCollector
    # creates this vhost itself, so it isn't covered by that block's edits.
    nginx.virtualHosts."cups.${home_domain}".http2 = false;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.cup_collector_env.restartUnits = [
      "cup-collector-pb-init.service"
      "cup-collector.service"
    ];
  };
}
