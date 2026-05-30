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
        {
          name = "Bragg Family";
          slug = "bragg_family";
        }
      ];
      migrationsDir = inputs.cup-collector.packages.${pkgs.stdenv.hostPlatform.system}.migrations;
      pbBindIp = "0.0.0.0";
      pbPort = config.dots.ports.pocketbase.port; # override default due to conflict
      pocketidIssuerUrl = config.services.pocket-id.settings.APP_URL;
      inherit (config.dots.ports.cup-collector) port; # override default due to conflict
    };

    restic.backups.daily = {
      paths = [
        config.services.cupCollector.dataDir
      ];
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.cup_collector_env.restartUnits = [
      "cup-collector-pb-init.service"
      "cup-collector.service"
    ];
  };
}
