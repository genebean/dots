{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.kiosk-hardware;
in
{
  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = lib.mkForce [
      "ext4"
      "f2fs"
      "vfat"
    ]; # kiosk-gene-desk's full list - small enough to just share as-is rather than juggle per-host overrides

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
    };

    networking = {
      firewall.enable = false;
      useNetworkd = true;
      wireless = {
        enable = true;
        interfaces = [ cfg.wirelessInterface ];
        secretsFile = config.sops.secrets.wifi_creds.path;
      };
    };

    sops.secrets.wifi_creds = {
      sopsFile = ../../shared/secrets.yaml; # two levels up from modules/genebean/nixos/, not three - this file lives at the nixos/ top level, not nested under programs/ or services/
      owner = "wpa_supplicant";
      restartUnits = [ "wpa_supplicant-${cfg.wirelessInterface}.service" ];
    };

    users.users.${username} = {
      isNormalUser = true;
      description = "Gene Liverman";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      linger = true;
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 90;
    };
  };
}
