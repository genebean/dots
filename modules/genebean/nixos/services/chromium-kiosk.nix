{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.chromium-kiosk;
  wifiInterface = lib.elemAt config.networking.wireless.interfaces 0;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wlr-randr ];

    services.cage = {
      enable = true;
      environment.WLR_LIBINPUT_NO_DEVICES = "1"; # boot up even if no mouse/keyboard connected
      program = pkgs.writeShellScript "kiosk.sh" ''
        WAYLAND_DISPLAY=wayland-0 wlr-randr --output ${cfg.wlrRandrOutput}${
          lib.optionalString (cfg.rotate != null) " --transform ${cfg.rotate}"
        }
        /etc/profiles/per-user/${username}/bin/chromium-browser
      '';
      user = username;
    };

    systemd.services.cage-tty1.wants = [
      "wpa_supplicant-${wifiInterface}.service"
      "network-online.target"
    ];
  };
}
