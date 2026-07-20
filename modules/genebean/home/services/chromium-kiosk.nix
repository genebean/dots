{ config, lib, ... }:
let
  cfg = config.genebean.services.chromium-kiosk;
in
{
  options.genebean.services.chromium-kiosk = {
    enable = lib.mkEnableOption "chromium kiosk pointed at a Home Assistant dashboard";

    dashboardUrl = lib.mkOption {
      type = lib.types.str;
      description = "URL chromium opens in --app/--kiosk mode.";
      example = "http://192.168.22.22:8123/kiosk-entryway/immich?kiosk";
    };

    extraCommandLineArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra chromium flags appended after the common kiosk set.";
      example = [ "--hide-scrollbars" ];
    };

    rotate = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "wlr-randr --transform value (e.g. \"90\", \"flipped-90\"). null = no --transform flag.";
    };

    wirelessInterface = lib.mkOption {
      type = lib.types.str;
      description = "Wireless interface name (e.g. wlan0, wlp3s0) - the NixOS side depends on wpa_supplicant-<interface>.service before starting the kiosk. Normally set to config.genebean.kiosk-hardware.wirelessInterface at the call site rather than duplicated.";
      example = "wlan0";
    };

    wlrRandrOutput = lib.mkOption {
      type = lib.types.str;
      default = "HDMI-A-1";
      description = "wlr-randr output name cage's compositor targets.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--app=${cfg.dashboardUrl}"
        "--kiosk"
        "--noerrdialogs"
        "--disable-infobars"
        "--no-first-run"
        "--ozone-platform=wayland"
        "--enable-features=OverlayScrollbar"
        "--start-maximized"
        "--force-dark-mode"
        "--hide-crash-restore-bubble"
      ]
      ++ cfg.extraCommandLineArgs;
    };
  };
}
