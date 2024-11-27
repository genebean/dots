{ lib, ... }:
{
  disko.devices = {
    disk = {
      sdc = {
        device = "/dev/disk/by-id/ata-SATA_SSD_H2101081000455";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "BOOT";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      }; # end sdc
      sdd = {
        device = "/dev/disk/by-id/ata-SATA_SSD_D2109088000361";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot-fallback = {
              name = "BOOT-FALLBACK";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot-fallback";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      }; # end sdd
      sda = {
        device = "/dev/disk/by-id/ata-TEAM_T2532TB_TPBF2401240030200343";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      }; # end sda
      sdb = {
        device = "/dev/disk/by-id/ata-TEAM_T2532TB_TPBF2401240030201870";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstorage";
              };
            };
          };
        };
      }; # end sdb
    };
    zpool = {
      zroot = {
        type = "zpool";
        mode = "mirror";
        # mountpoint = "none";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank";
        options = {
          ashift = "12";
          autotrim = "on";
          compatibility = "grub2";
        };
        rootFsOptions = {
          mountpoint = "none";
          atime = "off";
          acltype = "posixacl";
          xattr = "sa";
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
          };
          "root/home" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
          "root/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
        };
      }; # end zroot
    };
  };
}