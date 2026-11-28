# VictoriaLogs runs in its own nspawn container rather than flat on star1
# - it's about to be the one place aggregating journal data (including
# auth/sudo entries) from every host in the fleet, a more attractive
# target than most things running elsewhere. The point is blast-radius
# reduction if the app itself gets popped: a separate mount namespace
# means a compromised victoria-logs process doesn't get to see star1's
# other services' files, sockets, or secrets just by being on the same
# box - far fewer host file paths are directly reachable than if this
# ran flat. The network namespace/VLAN split is the same reasoning
# applied to the network side.
#
# This is new territory for this fleet, not an established pattern:
# tcan-left's Hermes containers (the only other nspawn containers here)
# use privateNetwork=false and share the host's network namespace
# entirely - there's no existing precedent for the
# privateNetwork=true+hostBridge+VLAN shape used below.
#
# Container-side interface is "eth0", confirmed against nixos-
# containers.nix's own containerInit script rather than guessed: it
# unconditionally renames the nspawn-assigned "host0" to "eth0" whenever
# HOST_BRIDGE is set (`ip link set host0 name eth0`), before NixOS's own
# networking.interfaces config ever evaluates - so "host0" never exists
# by the time this file's config applies. Getting this wrong wouldn't
# just affect this container - nothing could reach it at all, which
# breaks log shipping fleet-wide since every host's vector agent depends
# on it.
#
# Named star1-victorialogs, not just victorialogs - this also becomes the
# container's default hostname (NixOS containers set networking.hostName
# = mkDefault <attribute name>) and is what it'll answer to on VLAN
# 2331's LLMNR traffic, so it's worth disambiguating by host up front
# rather than after a second host grows an identically-named container.
#
# Auth is deliberately layered, not single-gated: pigate's nginx
# basicAuthFile (default.nix's /logsink location) covers the sanctioned
# path every vector agent actually uses, but does nothing for anyone who
# reaches this container directly over VLAN 2331 - the gap a security
# review of this branch flagged. services.victorialogs' own basicAuth
# below closes that regardless of network path. Same "logshipper"
# credential as pigate's layer, not a second one: nginx forwards the
# client's Authorization header upstream unchanged by default, so this
# validates for free with no extra nginx config, as long as both layers'
# secrets stay in sync (see modules/shared/secrets.yaml's logshipper_env,
# logshipper_nginx_basic_auth, and logshipper_victorialogs_pw - the same
# password in three forms for three different consumers).
{ config, lib, ... }:
let
  # UDM SE, VLAN 2331 - both the gateway and this network's DNS service.
  # One binding, not two separately-written literals, so the container's
  # networking config below can't have its gateway and nameserver drift
  # out of sync with each other.
  gatewayAddress = "192.168.23.97";
  # Captured by closure, not referenced inside the container's own module
  # evaluation below - containers.<name>.config is a separate, mostly-bare
  # NixOS module tree that doesn't inherit the host's genebean.ports
  # option at all, so config.genebean.ports can't be read from inside it.
  inherit (config.genebean.ports.victorialogs) port;
in
{
  containers.star1-victorialogs = {
    autoStart = true;

    bindMounts = {
      "/run/secrets/logshipper_victorialogs_pw" = {
        hostPath = config.sops.secrets.logshipper_victorialogs_pw.path;
        isReadOnly = true;
      };
      # The actual log data, off the host's small NVMe root and onto the
      # replicated bulk storage (disk-config.nix's victorialogs
      # subvolume) - the bcachefs equivalent of giving this its own ZFS
      # dataset. With the module's default DynamicUser=true, systemd's
      # own StateDirectory mechanism wants to fully own and create both
      # /var/lib/victorialogs (the public alias) and
      # /var/lib/private/victorialogs (the real backing dir) itself
      # from scratch at every start - bind-mounting onto either one
      # collides with that (confirmed live: "Device or resource busy"
      # at the public path, then "File exists" at the private one once
      # tried there instead). systemd.services.victorialogs below turns
      # DynamicUser off specifically so StateDirectory falls back to
      # its much simpler non-dynamic behavior - plain mkdir + chown to
      # a static user, no bind-mount dance at all - which is fully
      # compatible with an external bind mount already sitting at this
      # path. /storage/victorialogs has neededForBoot = false
      # (default.nix), so it can mount later than early boot -
      # nixos-containers.nix automatically adds every bindMount
      # hostPath here to this container's own systemd unit's
      # RequiresMountsFor, so the container still won't start before
      # this is actually mounted.
      "/var/lib/victorialogs" = {
        hostPath = "/storage/victorialogs";
        isReadOnly = false;
      };
    };

    config = _: {
      system.stateVersion = "26.05";

      networking = {
        # networkd requires the interface a default route attaches to be
        # named explicitly - the plain-string form is a script-based-
        # networking-only shorthand.
        defaultGateway = {
          address = gatewayAddress;
          interface = "eth0";
        };
        firewall.allowedTCPPorts = [ port ];
        interfaces.eth0.ipv4.addresses = [
          {
            address = "192.168.23.98";
            prefixLength = 27;
          }
        ];
        # Same UDM SE as the gateway above - it's also this network's
        # DNS service, and resolved has nothing to fall back to otherwise
        # (no DHCP to learn a resolver from, useHostResolvConf is off).
        nameservers = [ gatewayAddress ];
        useDHCP = false;
        # Container defaults to inheriting the host's resolv.conf for
        # convenience, which systemd-resolved (enabled below) can't
        # coexist with - resolved manages its own.
        useHostResolvConf = false;
        useNetworkd = true;
      };

      services = {
        resolved.enable = true;
        timesyncd.enable = true;

        victorialogs = {
          enable = true;
          basicAuthPasswordFile = "/run/secrets/logshipper_victorialogs_pw";
          basicAuthUsername = "logshipper";
          listenAddress = ":${toString port}";
        };
      };

      # See bindMounts' /var/lib/victorialogs comment above for why
      # DynamicUser needs to be off here. A static user/group instead of
      # the module's own dynamically-allocated one - StateDirectory still
      # chowns /var/lib/victorialogs to this on every start, same as it
      # would for a DynamicUser, just without the bind-mount-incompatible
      # private-directory dance.
      systemd.services.victorialogs.serviceConfig = {
        # mkForce: nixos-containers.nix and the victorialogs module each
        # set DynamicUser at the same priority (true vs false) -
        # confirmed live via the resulting "conflicting definition
        # values" eval error without this.
        DynamicUser = lib.mkForce false;
        Group = "victorialogs";
        User = "victorialogs";
      };

      users = {
        groups.victorialogs = { };
        users.victorialogs = {
          group = "victorialogs";
          isSystemUser = true;
        };
      };
    };

    hostBridge = "br-observe";
    privateNetwork = true;
  };

  # Decrypted on the host (this container has no sops-nix of its own) and
  # bind-mounted in below - victoria-logs reads it via systemd
  # LoadCredential, which the container's own PID1 (real root, no user
  # namespacing here) resolves before dropping to victorialogs' static
  # user, so the bind-mounted file can stay root-only (sops-nix's default
  # mode).
  sops.secrets.logshipper_victorialogs_pw = {
    # Restarts the whole container, not just victorialogs.service inside
    # it - there's no host-level restartUnits path to a unit living in a
    # separate container's own systemd instance. Heavier than ideal, but
    # correct, and rotation of this secret should be rare.
    restartUnits = [ "container@star1-victorialogs.service" ];
    sopsFile = ../../../../shared/secrets.yaml;
  };
}
