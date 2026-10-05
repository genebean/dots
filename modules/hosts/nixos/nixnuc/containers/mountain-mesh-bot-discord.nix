{ config, ... }:
let
  volume_base = "/orico/mountain-mesh-bot-discord";
in
{
  # My mountain-mesh-bot-discord container

  virtualisation.oci-containers.containers = {
    "mtnmesh_bot_discord" = {
      autoStart = true;
      image = "ghcr.io/genebean/mountain-mesh-bot-discord:v1.0.0";
      volumes = [
        "${volume_base}/.env:/src/.env"
      ];
    };
  };

  services.restic.backups.daily.paths = [ volume_base ];

  sops.secrets.mtnmesh_bot_dot_env = {
    path = "${volume_base}/.env";
    # `serviceName` is bare; sops-nix's `restartUnits` needs the full unit
    # name or it ends up in the legacy activation-script restart path and
    # gets handed to switch-to-configuration-ng without a type suffix,
    # which systemd's D-Bus API (unlike the `systemctl` CLI) rejects
    # outright: "Unit name podman-mtnmesh_bot_discord is not valid"
    # (dots#741).
    restartUnits = [
      "${config.virtualisation.oci-containers.containers.mtnmesh_bot_discord.serviceName}.service"
    ];
  };
}
