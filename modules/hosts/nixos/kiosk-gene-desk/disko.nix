{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = lib.mkDefault "/dev/mmcblk0";

      content = {
        type = "gpt";
        # `priority` pins physical partition order. This matters beyond
        # readability: the Pi's GPU/EEPROM boot ROM always reads *physical
        # partition 1* for its own firmware (start.elf, fixup.dat,
        # config.txt), regardless of partition labels - it doesn't
        # understand GPT names at that stage. Without explicit priorities
        # here, disko orders partitions by attrset key (alphabetical),
        # which put ESP before FIRMWARE and left the Pi unable to find its
        # firmware at all.
        partitions = {
          # Loaded directly by the Pi's GPU/EEPROM boot ROM: RPi firmware
          # (a.k.a "boot code") + the u-boot binary named in config.txt.
          # Kept in sync by boot.loader.raspberry-pi on every switch. Must
          # be physical partition 1 - see note above.
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

          # Read by u-boot (once it's running) for extlinux.conf, kernel
          # and initrd. Needs to be its own real partition, not a
          # directory under / - u-boot reads it before this boot's
          # activation scripts (which repopulate it) ever run, and / is
          # tmpfs so it wouldn't survive a reboot otherwise.
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

          # The nix store, rebuilt by every `nixos-rebuild switch`. Fixed
          # size rather than 100% so /persist gets real space below; 20G
          # is ~2x current store usage.
          nix = {
            priority = 3;
            label = "NIX";
            type = "8305"; # Linux ARM64 root (/)
            size = "20G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = [
                "noatime"
                "nodiratime"
              ];
            };
          };

          # Explicit persistence allowlist - see persistence.nix. f2fs
          # for write-amplification reasons (this is where the write-heavy
          # chromium cache lives). Takes whatever's left on the card.
          persist = {
            priority = 4;
            label = "PERSIST";
            type = "8305";
            size = "100%";
            content = {
              type = "filesystem";
              format = "f2fs";
              mountpoint = "/persist";
              mountOptions = [
                "noatime"
                "nodiratime"
              ];
            };
          };
        };
      };
    };

    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=512M"
        "mode=755"
      ];
    };
  };
}
