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
    # This vhost's own ACME/TLS are disabled below (enableACME/forceSSL) -
    # that was fine when nginx lived on nixnuc, but pigate is the public
    # edge now. Keep cup-collector's own locations/extraConfig (merged in
    # from its module untouched) but redirect this vhost to plain HTTP on
    # the services VLAN, matching nextcloud/podcasts/newspaper - pigate's
    # own "cups.${home_domain}" vhost (pigate's default.nix) owns the real
    # public ACME cert and proxies here by Host header.
    nginx.virtualHosts."cups.${home_domain}".listen = [
      {
        addr = "192.168.23.130";
        port = 80;
      }
    ];
    cupCollector = {
      enable = true;
      enableACME = false;
      forceSSL = false;
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
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.cup_collector_env.restartUnits = [
      "cup-collector-pb-init.service"
      "cup-collector.service"
    ];
  };
}
