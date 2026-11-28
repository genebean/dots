# A second, dedicated Vector instance for receiving syslog (TCP and UDP)
# from network appliances - routers, switches, printers, anything that
# only speaks syslog, not HTTP or journald. Kept out of
# star1-victorialogs' own container rather than added there as a second
# source, because this one has a fundamentally different reachability
# requirement: appliances need to reach it directly (syslog has no
# reverse-proxy-friendly protocol the way HTTP does, so pigate can't
# front this the way it fronts everything else), whereas victorialogs
# itself is deliberately reachable only from pigate and this VLAN.
#
# Talks to victorialogs directly over VLAN 2331 rather than round-
# tripping through pigate's /logsink like every host-based vector agent
# does - both containers already sit on the same VLAN, so there's no
# reason to leave it and come back. Reuses the fleet's existing
# logshipper credential (modules/shared/secrets.yaml's logshipper_env,
# already bound to a "logshipper" user at every layer this fleet talks
# to VictoriaLogs through) rather than a new one.
#
# Network is built on extraVeths, not just the primary hostBridge
# interface, so more interfaces can be added later without restructuring
# anything - e.g. to make the UDP listener reachable from an additional
# subnet, add another entry here:
#
#   extraVeths.vlanNNNN = {
#     hostBridge = "br-whatever";
#     localAddress = "10.x.x.x/24";
#   };
#
# Vector's syslog sources below bind 0.0.0.0, so a newly-added interface
# starts receiving on it immediately - no vector config changes needed,
# just the interface.
{ config, ... }:
let
  gatewayAddress = "192.168.23.97"; # UDM SE, VLAN 2331
  syslogPort = 514;
  # star1-victorialogs' address (containers/victorialogs.nix) - hardcoded
  # here rather than threaded through, same as pigate's own
  # star1_victorialogs_ip; these two containers aren't otherwise coupled
  # enough to justify a shared file just for one IP literal.
  victorialogsAddress = "192.168.23.98";
  victorialogsPort = config.genebean.ports.victorialogs.port;
in
{
  containers.star1-syslog-vector = {
    autoStart = true;

    bindMounts."/run/secrets/logshipper_env" = {
      hostPath = config.sops.secrets.logshipper_env.path;
      isReadOnly = true;
    };

    config =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Same reasoning as log-shipping.nix's own vectorConfigTemplate -
        # vector doesn't interpolate ${LOGSHIPPER_PASSWORD} itself, so this
        # gets rendered via envsubst at service start instead (see
        # systemd.services.vector's ExecStart override below).
        vectorConfigTemplate =
          (pkgs.formats.toml { }).generate "vector.toml"
            config.services.vector.settings;
      in
      {
        system.stateVersion = "26.05";

        networking = {
          defaultGateway = {
            address = gatewayAddress;
            interface = "eth0";
          };
          firewall = {
            allowedTCPPorts = [ syslogPort ];
            allowedUDPPorts = [ syslogPort ];
          };
          # "eth0", not nspawn's own "host0" - confirmed against nixos-
          # containers.nix's containerInit script (see
          # containers/victorialogs.nix's own comment on this).
          interfaces.eth0.ipv4.addresses = [
            {
              address = "192.168.23.99"; # next address after victorialogs' .98
              prefixLength = 27;
            }
          ];
          nameservers = [ gatewayAddress ];
          useDHCP = false;
          useHostResolvConf = false;
          useNetworkd = true;
        };

        services = {
          resolved.enable = true;
          timesyncd.enable = true;

          vector = {
            enable = true;

            settings = {
              sinks.victorialogs = {
                auth = {
                  password = "\${LOGSHIPPER_PASSWORD}";
                  strategy = "basic";
                  user = "logshipper";
                };
                # Disk-backed, not vector's default in-memory buffer - unlike
                # the journald-sourced sinks (log-shipping.nix), syslog has no
                # durable source behind it to fall back on: once a UDP packet
                # is received, Vector's buffer is the only thing standing
                # between a VictoriaLogs outage and permanently lost logs.
                # 268435488 is disk buffers' own minimum size, not a sizing
                # choice; data_dir isn't set, since its default
                # (/var/lib/vector) already matches this service's
                # StateDirectory.
                buffer = {
                  max_size = 268435488;
                  type = "disk";
                  when_full = "block";
                };
                compression = "gzip";
                encoding.codec = "json";
                framing.method = "newline_delimited";
                healthcheck.enabled = false;
                inputs = [
                  "syslog_tcp"
                  "syslog_udp"
                ];
                type = "http";
                # vector's syslog source normalizes to host/message/timestamp,
                # same as its journald source - see the _stream_fields used
                # fleet-wide in log-shipping.nix. No per-unit second field
                # here (syslog's equivalent would be "appname", not
                # journald's _SYSTEMD_UNIT) - stream by host alone until
                # there's a reason to split further.
                uri = "http://${victorialogsAddress}:${toString victorialogsPort}/insert/jsonline?_stream_fields=host&_msg_field=message&_time_field=timestamp";
              };

              sources = {
                syslog_tcp = {
                  address = "0.0.0.0:${toString syslogPort}";
                  mode = "tcp";
                  type = "syslog";
                };
                syslog_udp = {
                  address = "0.0.0.0:${toString syslogPort}";
                  mode = "udp";
                  type = "syslog";
                };
              };
            };

            # vector's own systemd unit already grants AmbientCapabilities
            # = CAP_NET_BIND_SERVICE (nixpkgs' vector.nix), unlike
            # victorialogs' module - so binding the real syslog port (514,
            # privileged) needs no extra wiring here.
            validateConfig = false; # see log-shipping.nix's own comment on this - same reason
          };
        };

        systemd.services.vector.serviceConfig = {
          EnvironmentFile = "/run/secrets/logshipper_env";
          # See log-shipping.nix's own ExecStart override comment - same
          # envsubst-at-start-time rendering, same reason.
          ExecStart = lib.mkForce ''
            ${pkgs.bash}/bin/bash -c '${pkgs.gettext}/bin/envsubst < ${vectorConfigTemplate} > /run/vector/vector-rendered.toml && exec ${lib.getExe config.services.vector.package} --config /run/vector/vector-rendered.toml --graceful-shutdown-limit-secs ${toString config.services.vector.gracefulShutdownLimitSecs}'
          '';
          RuntimeDirectory = "vector";
        };
      };

    hostBridge = "br-observe";
    privateNetwork = true;
  };

  # Appends to the shared secret's own restartUnits (modules/shared/nixos/
  # log-shipping.nix) rather than editing it there - that module is
  # imported fleet-wide, and this unit only exists on star1.
  sops.secrets.logshipper_env.restartUnits = [
    "container@star1-syslog-vector.service"
  ];
}
