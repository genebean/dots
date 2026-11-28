{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./monitoring.nix
  ];

  system.stateVersion = "26.05";

  boot = {
    # bcachefs is out-of-tree again (kernel maintainer conflict, back to a
    # DKMS-style module) - the installer ISO carries this same wiring
    # (pkgs/bcachefs-installer-iso) for format-time support, but that
    # doesn't carry over to the installed system on its own. Without this,
    # a future kernel update could leave this host unable to mount its own
    # bcachefs root on reboot.
    #
    # kernelPackages (below) is pinned to linuxPackages_latest (7.3) rather
    # than the default (6.18) kernel, same as tcan-left: 6.18's latest
    # point release collides with new VFS inode-state accessor functions
    # landing in linux/fs.h, which breaks the bcachefs-tools DKMS module
    # (NixOS/nixpkgs issue 591440, filed upstream, unresolved as of this
    # commit). 6.16/6.17/6.19 are EOL'd out of the nixpkgs tree entirely, so
    # 7.3 is the only other kernel line available. This also removes the
    # earlier zfs/bcachefs conflict this host had (zfs and the bcachefs DKMS
    # module want different kernel lines, and only one filesystem driver is
    # needed now that storage/disk-config.nix moved the "storage" pool off
    # zfs and onto a second bcachefs filesystem) - supportedFilesystems no
    # longer needs "zfs" at all.
    extraModulePackages = [ config.boot.kernelPackages.bcachefs ];
    kernelPackages = pkgs.linuxPackages_latest;
    # Real UEFI hardware (confirmed via /sys/firmware/efi on the live
    # installer), not a cloud VM - systemd-boot over GRUB.
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    supportedFilesystems = [ "bcachefs" ];
  };

  environment.systemPackages = with pkgs; [
    bcachefs-tools
  ];

  # disko's bcachefs_filesystem type hardcodes neededForBoot = true on
  # every mounted subvolume (lib/types/bcachefs_filesystem.nix) - unlike
  # the zpool type disk-config.nix's "storage" filesystem used to use,
  # which never set this at all. Without this override, a problem
  # assembling this bulk-storage filesystem (both drives, not just one -
  # replicas=2 tolerates a single failed device) would now block star1
  # from booting at all, same as if root itself failed to mount. /storage
  # isn't needed for the system to come up, so it shouldn't be able to
  # stop it from doing so.
  fileSystems."/storage".neededForBoot = lib.mkForce false;

  networking = {
    firewall = {
      allowedTCPPorts = lib.pipe config.genebean.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "tcp"))
        (map (e: e.port))
      ];
      allowedUDPPorts = lib.pipe config.genebean.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "udp"))
        (map (e: e.port))
      ];
    };

    hostId = "e88c847d"; # head -c4 /dev/urandom | od -A none -t x4

    # Only active NIC at install time (confirmed via `ip -brief link` on
    # the live installer) - wlan0 (RTL8852BE) exists but was DOWN/unused.
    interfaces.enp2s0.useDHCP = true;
    networkmanager.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  programs.mtr.enable = true;

  services = {
    fail2ban.enable = true;
    fwupd.enable = true;
    logrotate.enable = true;
    resolved.enable = true;
    # autodetect (default true) covers the NVMe root disk too - modern
    # smartmontools detects NVMe under DEVICESCAN natively, same as nixnuc.
    smartd.enable = true;
  };

  sops.defaultSopsFile = ./secrets.yaml;

  users.users.${username} = {
    description = "Gene Liverman";
    extraGroups = [ "wheel" ];
    isNormalUser = true;
    linger = true;
  };

  # No swap partition (disk-config.nix) - zramSwap instead, same reasoning
  # as tcan-left (bcachefs' native swapfile support is still maturing).
  zramSwap.enable = true;
}
