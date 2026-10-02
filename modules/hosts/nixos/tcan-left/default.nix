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
    ./hermes-leo.nix
    ./monitoring.nix
    ./ollama.nix
    ./ports.nix
  ];

  system.stateVersion = "26.05";

  boot = {
    # Real UEFI hardware (confirmed via /sys/firmware/efi on the live
    # installer), not a cloud VM - systemd-boot over GRUB, no need for
    # GRUB's efiInstallAsRemovable workaround that hetznix01's KVM-based
    # host needs.
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };

    # bcachefs is out-of-tree again (kernel maintainer conflict, back to a
    # DKMS-style module) - the installer ISO carries this same wiring
    # (pkgs/bcachefs-installer-iso) for format-time support, but that
    # doesn't carry over to the installed system on its own. Without this,
    # a future kernel update could leave this host unable to mount its own
    # bcachefs root on reboot.
    extraModulePackages = [ config.boot.kernelPackages.bcachefs ];
    supportedFilesystems = [ "bcachefs" ];
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

    hostId = "f1fae95a"; # head -c4 /dev/urandom | od -A none -t x4

    useDHCP = false;
    networkmanager.enable = false;
    useNetworkd = true;
    # Only active NIC at install time (confirmed via `ip -brief link` on
    # the live installer) - enp12s0 exists (dual-NIC Mac Pro) but was
    # DOWN/unconnected.
    interfaces.enp11s0.useDHCP = true;
  };

  programs.mtr.enable = true;

  services = {
    fail2ban.enable = true;
    logrotate.enable = true;
    resolved.enable = true;
  };

  sops.defaultSopsFile = ./secrets.yaml;

  # No swap partition (disk-config.nix) - bcachefs' native swapfile
  # support is still maturing, zram is simpler and this host has plenty
  # of RAM to make it effective.
  zramSwap.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "wheel" ];
    linger = true;
  };
}
