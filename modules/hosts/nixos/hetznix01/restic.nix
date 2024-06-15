{ ... }: {
  imports = [
    ../../../system/common/linux/restic.nix
  ];

  services.restic.backups.daily.paths = [
    "/var/lib/uptime-kuma"
  ];
}

