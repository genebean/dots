{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./containers/syslog-vector.nix
    ./containers/victorialogs.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./monitoring.nix
    ../../../shared/nixos/log-shipping.nix
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

  # VLAN 2331 ("observability" in UniFi) - 192.168.23.96/27, UDM SE at .97.
  # Carries the containers backing star1's observability/AI-gateway stack
  # (VictoriaLogs first; VictoriaMetrics/Grafana, Tempo, LiteLLM to follow).
  # Kept separate from nixnuc's existing services VLAN on purpose: same
  # "only pigate may reach this" reachability model, but a different trust
  # domain on a different physical host - sharing one VLAN would let
  # same-VLAN traffic between the two hosts skip the UDM's inter-VLAN
  # firewall entirely (plain L2, no router hop), losing the second
  # enforcement layer behind each container's own nftables rules.
  #
  # Rides enp2s0's sibling 2.5G port (enp3s0) as the VLAN's untagged/access
  # port - the switch port it's plugged into is configured for VLAN 2331
  # untagged, so no 802.1Q tagging is needed on the host side at all
  # (no vlans.* config, unlike a trunked port). Keeps this VLAN's traffic
  # on its own physical NIC entirely, separate from enp2s0's own untagged
  # management traffic.
  #
  # No IP assigned to the bridge itself - nothing on star1's own host
  # network namespace needs to originate traffic on this VLAN today (star1
  # ships its own journal through pigate's /logsink like every other host,
  # not directly to the container). Only the containers attached via
  # hostBridge below get addresses here.
  networking = {
    bridges.br-observe.interfaces = [ "enp3s0" ];
    # This host's own vector agent (log-shipping.nix) ships over this
    # host's own network, not a container's - the public hostname's
    # hairpin NAT path back through the UniFi doesn't work reliably for
    # on-prem callers, same reasoning as nixnuc/id.home.technicalissues.us.
    extraHosts = ''
      192.168.23.2 monitoring.home.technicalissues.us
    '';
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

    interfaces = {
      # networking.bridges only generates a .network file for each member
      # interface (telling it to join the bridge) - not for the bridge
      # device itself, so without this it stays unmanaged by networkd and
      # never comes up, silently failing to forward anything between
      # enp3s0 and the containers attached via hostBridge. No address
      # needed - this just gets it managed and brought up.
      br-observe.useDHCP = false;
      # Only active NIC at install time (confirmed via `ip -brief link` on
      # the live installer) - wlan0 (RTL8852BE) exists but was DOWN/unused.
      enp2s0.useDHCP = true;
    };
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
