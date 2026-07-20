{ lib, ... }:
{
  options.genebean.kiosk-hardware = {
    enable = lib.mkEnableOption "shared NixOS-level config for small headless kiosk boxes";

    wirelessInterface = lib.mkOption {
      type = lib.types.str;
      description = "Wireless interface name (e.g. wlan0, wlp3s0). Feeds networking.wireless.interfaces directly. genebean.services.chromium-kiosk has its own wirelessInterface option for its wpa_supplicant dependency - set that to config.genebean.kiosk-hardware.wirelessInterface at the call site rather than duplicating the value.";
    };
  };
}
