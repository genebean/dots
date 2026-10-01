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
    # Real UEFI hardware (confirmed via /sys/firmware/efi on the live
    # installer), not a cloud VM - systemd-boot over GRUB.
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };

    # bcachefs is out-of-tree again (kernel maintainer conflict, back to a
    # DKMS-style module) - the installer ISO carries this same wiring
    # (pkgs/bcachefs-installer-iso) for format-time support, but that
    # doesn't carry over to the installed system on its own. Without this,
    # a future kernel update could leave this host unable to mount its own
    # bcachefs root on reboot. zfs is added here too, for the mirrored
    # "storage" pool.
    extraModulePackages = [ config.boot.kernelPackages.bcachefs ];
    supportedFilesystems = [
      "bcachefs"
      "zfs"
    ];
    # Not a root pool (bcachefs owns root here) - matches nixnuc's own
    # zfs.forceImportRoot = false for the same reason: nothing to force-import
    # at boot, and it's the recommended-going-forward default anyway.
    zfs.forceImportRoot = false;
  };

  environment.systemPackages = with pkgs; [
    bcachefs-tools
  ];

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

    useDHCP = false;
    networkmanager.enable = false;
    useNetworkd = true;
    # Only active NIC at install time (confirmed via `ip -brief link` on
    # the live installer) - wlan0 (RTL8852BE) exists but was DOWN/unused.
    interfaces.enp2s0.useDHCP = true;
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

  # No swap partition (disk-config.nix) - zramSwap instead, same reasoning
  # as tcan-left (bcachefs' native swapfile support is still maturing).
  zramSwap.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "wheel" ];
    linger = true;
  };
}
