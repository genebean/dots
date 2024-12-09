{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    restic
  ];

  sops.secrets = {
    restic_env.sopsFile = ../secrets.yaml;
    restic_repo.sopsFile = ../secrets.yaml;
    restic_password.sopsFile = ../secrets.yaml;
  };

  services.restic.backups = {
    daily = {
      initialize = true;

      environmentFile = config.sops.secrets.restic_env.path;
      repositoryFile = config.sops.secrets.restic_repo.path;
      passwordFile = config.sops.secrets.restic_password.path;

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 6"
      ];
    };
  };
}

