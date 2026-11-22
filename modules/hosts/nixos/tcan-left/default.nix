# tcan-left: one of two "trashcan" Mac Pros (the cylindrical 2013 design)
# in the same rack mount - this is the left one.
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
    #
    # kernelPackages is pinned to linuxPackages_latest (7.3) rather than the
    # default (6.18) kernel: 6.18's latest point release collides with new
    # VFS inode-state accessor functions landing in linux/fs.h, which breaks
    # the bcachefs-tools DKMS module (NixOS/nixpkgs issue 591440, filed
    # upstream, unresolved as of this commit). 6.16/6.17/6.19 are EOL'd out
    # of the nixpkgs tree entirely, so 7.3 - confirmed building the module
    # cleanly with the main nixpkgs' current bcachefs-tools - is the only
    # other kernel line available. Superseded an earlier commit that pinned
    # a whole separate, frozen nixpkgs revision for this instead; prefer
    # this one going forward since it stays on the main nixpkgs input.
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [ config.boot.kernelPackages.bcachefs ];
    supportedFilesystems = [ "bcachefs" ];
  };

  networking = {
    # No social-reader-mcp hosts entry here on the bare host - only
    # Danny's own container (hermes/danny/social-digest.nix) actually
    # talks to the MCP, so that's the only place that needs it.
    # privateNetwork=false shares the network namespace, not /etc/hosts,
    # which is per-container (hermes-agent-fleet-plan issue 37/40).

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
