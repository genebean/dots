# by-id path, not /dev/sda: this is the internal Apple SSD specifically
# (confirmed via lsblk on the live installer) - the boot USB installer
# itself shows up as a separate disk and must never be a disko target.
#
# bcachefs root: deliberately experimental - the owner wants to try it on
# a non-critical host. Three subvolumes, not a flat root, chosen so a
# future snapshot policy has useful boundaries without needing to
# retrofit them later (subvolume splits are much cheaper to decide before
# data exists than after):
#   - nix:      regenerable from this flake, never worth snapshotting -
#               excluded from root so a root snapshot doesn't also drag
#               the whole (large) store along with it
#   - root (/): OS-level /etc etc. NixOS's own generation rollback already
#               covers most of what a root snapshot would buy you
#   - var-lib:  where actual service state lands on NixOS (databases, app
#               data) - the genuinely non-regenerable stuff worth being
#               able to snapshot/roll back independently once this host
#               has real workloads
# /home deliberately stays under the root subvolume, not split out: unlike
# a desktop (bigboy), a services host's /home/gene is almost entirely
# reproducible dotfiles (home-manager) and sops-recoverable SSH keys, not
# irreplaceable personal data - not worth a fourth boundary decided today.
#
# No separate swap partition - zramSwap.nix handles memory pressure
# instead, simpler than bcachefs' still-maturing native swapfile support.
{
  disko.devices = {
    disk.disk1 = {
      device = "/dev/disk/by-id/ata-APPLE_SSD_SM0256G_S2ZGNY0KC02463";
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
              # Invalid argument (os error 22)" - confirmed via a real
              # failed install. A non-empty label is required even for a
              # single-disk filesystem.
              label = "main.disk1";
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
  };
}
