{
  lib,
  pkgs,
  username,
  ...
}:
{
  # ------------------------------------------------------------------ #
  # Read-only SD card mounts and tmpfs for writable paths
  # ------------------------------------------------------------------ #
  fileSystems = {
    "/" = lib.mkForce {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [
        "ro"
        "noatime"
        "nodiratime"
      ];
    };

    "/boot/firmware" = lib.mkForce {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [
        "ro"
        "noatime"
        "nofail"
        "noauto"
      ];
    };

    "/var/log" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "size=64m"
        "mode=0755"
        "nosuid"
        "nodev"
      ];
      neededForBoot = true;
    };

    "/var/lib" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "size=256m"
        "mode=0755"
        "nosuid"
        "nodev"
      ];
      neededForBoot = true;
    };

    "/home/${username}/.cache" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "size=256m"
        "mode=0700"
        "uid=1000"
        "nosuid"
        "nodev"
      ];
    };

    "/home/${username}/.local" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "size=256m"
        "mode=0700"
        "uid=1000"
        "nosuid"
        "nodev"
      ];
    };

    "/home/${username}/.config/chromium" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "size=128m"
        "mode=0700"
        "uid=1000"
        "nosuid"
        "nodev"
      ];
    };
  };

  # ------------------------------------------------------------------ #
  # tmpfs for paths that need to be writable at runtime
  # ------------------------------------------------------------------ #

  # /tmp - NixOS built-in option, cleaner than a manual fileSystems entry
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "20%";

  # ------------------------------------------------------------------ #
  # systemd-journal needs its directory to exist after /var/log tmpfs
  # is mounted
  # ------------------------------------------------------------------ #
  systemd.tmpfiles.rules = [
    "d /var/log/journal 0755 root systemd-journal -"
    # create a writable zsh history file in /tmp for gene
    "f /tmp/zsh_history_gene 0600 ${username} users -"
  ];

  # ------------------------------------------------------------------ #
  # Helper scripts for doing a nixos-rebuild
  # ------------------------------------------------------------------ #
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "remount-rw" ''
      echo "Remounting / read-write..."
      sudo mount -o remount,rw /

      echo "Starting nix-daemon..."
      systemctl start nix-daemon.socket nix-daemon.service

      echo "Done. Run 'reboot' when finished."
    '')
  ];
}
