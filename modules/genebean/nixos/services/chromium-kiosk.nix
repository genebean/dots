{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.chromium-kiosk;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wlr-randr ];

    fonts = {
      fontconfig = {
        enable = true;
        useEmbeddedBitmaps = true;
      };
      packages = with pkgs; [
        noto-fonts
        noto-fonts-color-emoji
        noto-fonts-cjk-sans
      ];
    };

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

    systemd.services = {
      # cage-tty1 already Conflicts=getty@tty1.service (set by upstream's
      # cage module) to stop both fighting over the same TTY, but that
      # alone doesn't prevent getty@tty1 from being reintroduced later.
      # Confirmed on hardware: NixOS's activation reactivates TTY-related
      # units on every `switch` and (re)starts getty@tty1.service
      # regardless of it showing "disabled" - the Conflicts= then kills
      # cage-tty1 as a side effect, and nothing re-triggers it afterward
      # (WantedBy=graphical.target doesn't get re-evaluated once that
      # target's already reached), leaving the kiosk dark until a manual
      # restart. Masking getty@tty1 outright - the standard practice for
      # a TTY a compositor owns exclusively - removes the conflict at its
      # source... except getty@.service's own upstream unit carries
      # Alias=autovt@%i.service, so masking the getty@tty1 name alone
      # doesn't stop systemd resolving the SAME underlying unit via its
      # autovt@tty1 alias instead - confirmed on hardware, masking only
      # getty@tty1 still left autovt@tty1.service starting at the exact
      # moment cage-tty1 died. Both names need masking.
      "autovt@tty1".enable = false;

      cage-tty1 = {
        # Upstream's cage module sets restartIfChanged = false, presumably
        # to avoid yanking an interactive desktop session out from under
        # someone mid `nixos-rebuild switch`. That caution doesn't apply to
        # a kiosk - confirmed on hardware that without this override, a
        # config change (e.g. a new dashboard URL) requires a manual
        # `systemctl restart cage-tty1` (or a reboot) to actually take
        # effect, since the switch itself silently leaves the old
        # chromium/cage instance running.
        restartIfChanged = lib.mkForce true;
        wants = [
          "wpa_supplicant-${cfg.wirelessInterface}.service"
          "network-online.target"
        ];
      };

      # Masked alongside its autovt@tty1 alias above - see that entry's
      # comment for why both names are needed.
      "getty@tty1".enable = false;
    };
  };
}
