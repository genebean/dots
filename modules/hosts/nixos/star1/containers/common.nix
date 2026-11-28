# Shared baseline for every container on star1's "observability" VLAN
# (br-observe, 192.168.23.96/27) - the UDM SE at .97 is both gateway and
# DNS for this network, and every container here wants the same
# networkd/resolved/timesyncd setup regardless of what it actually runs.
# Each container's own config imports this and adds only what's specific
# to it (its own address, firewall ports, and the service it actually runs).
{
  system.stateVersion = "26.05";

  networking = {
    # networkd requires the interface a default route attaches to be
    # named explicitly - the plain-string form is a script-based-
    # networking-only shorthand. "eth0", not nspawn's own "host0" -
    # confirmed against nixos-containers.nix's containerInit script: it
    # unconditionally renames host0 to eth0 whenever HOST_BRIDGE is set,
    # before NixOS's own networking.interfaces config ever evaluates.
    defaultGateway = {
      address = "192.168.23.97"; # UDM SE, VLAN 2331
      interface = "eth0";
    };
    # Same UDM SE as the gateway above - it's also this network's DNS
    # service, and resolved has nothing to fall back to otherwise (no
    # DHCP to learn a resolver from, useHostResolvConf is off).
    nameservers = [ "192.168.23.97" ];
    useDHCP = false;
    # Container defaults to inheriting the host's resolv.conf for
    # convenience, which systemd-resolved (enabled below) can't coexist
    # with - resolved manages its own.
    useHostResolvConf = false;
    useNetworkd = true;
  };

  services = {
    resolved.enable = true;
    timesyncd.enable = true;
  };
}
