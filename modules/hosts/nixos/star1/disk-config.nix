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
# The two TEAM 1.9TB SATA drives are a second bcachefs filesystem
# ("storage", not "rpool" - that name means *root* pool by ZFS convention,
# which this isn't; not host-prefixed either, since unlike nixnuc's "orico"
# - named after an external enclosure brand - these are plain internal
# bays), replicated across both devices (--replicas=2) for the same
# single-drive-failure tolerance a ZFS mirror gave. Originally a mirrored
# ZFS pool - switched to bcachefs because zfs and the out-of-tree bcachefs
# DKMS module (see default.nix's kernelPackages comment) want different
# kernel lines, and running both on one host isn't possible. No data to
# preserve on the old pool, so this was a straight reformat, not a
# migration. No subvolumes pre-created beyond the one below - more get
# added (via a small systemd oneshot, same shape as nixnuc's
# zfs-datasets.nix) once this host's observability role is further along.
{
  disko.devices = {
    bcachefs_filesystems = {
      main = {
        extraFormatArgs = [ "--compression=zstd" ];
        subvolumes = {
          "subvolumes/nix" = {
            mountpoint = "/nix";
          };
          "subvolumes/root" = {
            mountpoint = "/";
          };
          "subvolumes/var-lib" = {
            mountpoint = "/var/lib";
          };
        };
        type = "bcachefs_filesystem";
      };

      storage = {
        extraFormatArgs = [
          "--compression=zstd"
          "--replicas=2"
        ];
        subvolumes = {
          "subvolumes/storage" = {
            mountpoint = "/storage";
          };
          # victorialogs' actual data dir, bind-mounted into the
          # star1-victorialogs container at /var/lib/victorialogs
          # (containers/victorialogs.nix) - off the small NVMe root and
          # onto the replicated bulk storage instead, same reasoning as a
          # dedicated ZFS dataset would have given it.
          "subvolumes/victorialogs" = {
            mountpoint = "/storage/victorialogs";
          };
        };
        type = "bcachefs_filesystem";
      };
    };

    disk = {
      disk1 = {
        content = {
          partitions = {
            esp = {
              content = {
                format = "vfat";
                mountOptions = [ "umask=0077" ];
                mountpoint = "/boot";
                type = "filesystem";
              };
              name = "ESP";
              size = "1G";
              type = "EF00";
            };
            root = {
              content = {
                filesystem = "main";
                # disko always emits `--label=${label}` to `bcachefs format`
                # regardless of device count; a genuinely empty `--label=`
                # makes bcachefs-tools fail with "error creating disk path:
                # Invalid argument (os error 22)" - a non-empty label is
                # required even for a single-disk filesystem.
                label = "main.disk1";
                type = "bcachefs";
              };
              name = "root";
              size = "100%";
            };
          };
          type = "gpt";
        };
        device = "/dev/disk/by-id/nvme-TS128GMTE110S_G986528553";
        type = "disk";
      };

      disk2 = {
        content = {
          partitions.storage = {
            content = {
              filesystem = "storage";
              label = "storage.disk2";
              type = "bcachefs";
            };
            size = "100%";
          };
          type = "gpt";
        };
        device = "/dev/disk/by-id/ata-TEAM_T2532TB_TPBF2401240030201870";
        type = "disk";
      };

      disk3 = {
        content = {
          partitions.storage = {
            content = {
              filesystem = "storage";
              label = "storage.disk3";
              type = "bcachefs";
            };
            size = "100%";
          };
          type = "gpt";
        };
        device = "/dev/disk/by-id/ata-TEAM_T2532TB_TPBF2401240030200343";
        type = "disk";
      };
    };
  };
}
