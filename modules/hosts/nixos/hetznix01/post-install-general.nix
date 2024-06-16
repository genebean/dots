{ config, username, ... }: {
  imports = [
    ../../../system/common/linux/restic.nix
  ];

  services = {
    restic.backups.daily.paths = [
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
    age.keyFile = /home/${username}/.config/sops/age/keys.txt;
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_git_config = {
        owner = "${username}";
        path = "/home/${username}/.gitconfig-local";
      };
      local_private_env = {
        owner = "${username}";
        path = "/home/${username}/.private-env";
      };
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  };
}