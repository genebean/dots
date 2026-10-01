# by-id paths, not /dev/sda - the boot USB installer itself shows up as a
# separate disk and must never be a disko target (confirmed via lsblk on the
# live installer).
#
# bcachefs root on the NVMe: same pattern as tcan-left, same installer
# image. Three subvolumes, not a flat root - see tcan-left/disk-config.nix
# for the full reasoning (nix/root/var-lib split chosen for future snapshot
# boundaries). /home stays under the root subvolume for the same reason
# given there: this is a services host, not a desktop, so /home/gene is
# almost entirely reproducible (home-manager, sops-recoverable SSH keys).
#
# No separate swap partition - zramSwap.nix handles memory pressure,
# consistent with tcan-left.
#
# The two TEAM 1.9TB SATA drives are a mirrored ZFS pool ("storage", not
# "rpool" - that name means *root* pool by ZFS convention, which this isn't;
# not host-prefixed either, since unlike nixnuc's "orico" - named after an
# external enclosure brand - these are plain internal bays). Provisioned as
# part of this same base install, not a fast-follow: the owner wants the
# base setup to cover the entire physical hardware stack in one pass. No
# datasets pre-created here - those get added (via a small systemd oneshot,
# same shape as nixnuc's zfs-datasets.nix) once this host is actually
# assigned a role.
{
  disko.devices = {
    disk = {
      disk1 = {
        device = "/dev/disk/by-id/nvme-TS128GMTE110S_G986528553";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "main";
                # disko always emits `--label=${label}` to `bcachefs format`
                # regardless of device count; a genuinely empty `--label=`
                # makes bcachefs-tools fail with "error creating disk path:
                # Invalid argument (os error 22)" - a non-empty label is
                # required even for a single-disk filesystem.
                label = "main.disk1";
              };
            };
          };
        };
      };

      disk2 = {
        device = "/dev/disk/by-id/ata-TEAM_T2532TB_TPBF2401240030201870";
        type = "disk";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "storage";
            };
          };
        };
      };

      disk3 = {
        device = "/dev/disk/by-id/ata-TEAM_T2532TB_TPBF2401240030200343";
        type = "disk";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "storage";
            };
          };
        };
      };
    };

    bcachefs_filesystems.main = {
      type = "bcachefs_filesystem";
      extraFormatArgs = [ "--compression=zstd" ];
      subvolumes = {
        "subvolumes/root" = {
          mountpoint = "/";
        };
        "subvolumes/nix" = {
          mountpoint = "/nix";
        };
        "subvolumes/var-lib" = {
          mountpoint = "/var/lib";
        };
      };
    };

    zpool.storage = {
      type = "zpool";
      mode = "mirror";
      rootFsOptions = {
        compression = "zstd";
      };
      mountpoint = "/storage";
    };
  };
}
