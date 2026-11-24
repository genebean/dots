{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = lib.mkDefault "/dev/mmcblk0";

      content = {
        type = "gpt";
        # `priority` pins physical partition order - the Pi's GPU/EEPROM
        # boot ROM always reads physical partition 1 for its own firmware
        # (start.elf, fixup.dat, config.txt) regardless of GPT labels. See
        # kiosk-gene-desk/disko.nix, which hit this first.
        partitions = {
          FIRMWARE = {
            priority = 1;
            label = "FIRMWARE";
            type = "0700"; # Microsoft basic data
            attributes = [ 0 ]; # Required Partition
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
              ];
            };
          };

          # Read by u-boot for extlinux.conf, kernel and initrd.
          ESP = {
            priority = 2;
            label = "ESP";
            type = "EF00"; # EFI System Partition
            attributes = [ 2 ]; # Legacy BIOS Bootable, so u-boot finds it
            size = "256M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "noatime"
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=1min"
                "umask=0077"
              ];
            };
          };

          # Persistent root (unlike kiosk-gene-desk's tmpfs-root
          # impermanence setup - this is a gateway, not a kiosk, so the
          # simpler persistent layout is the right one). f2fs for
          # write-amplification reasons: this card also hosts CrowdSec/
          # fail2ban's databases and nginx's logs, all write-heavy.
          root = {
            priority = 3;
            label = "ROOT";
            type = "8305"; # Linux ARM64 root (/)
            size = "100%";
            content = {
              type = "filesystem";
              format = "f2fs";
              mountpoint = "/";
              mountOptions = [
                "noatime"
                "nodiratime"
              ];
            };
          };
        };
      };
    };
  };
}
