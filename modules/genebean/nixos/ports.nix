{ lib, ... }:
{
  options.genebean.ports = lib.mkOption {
    description = "Fleet-wide service port registry";
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "Port number";
          };
          protocol = lib.mkOption {
            type = lib.types.enum [
              "tcp"
              "udp"
            ];
            default = "tcp";
            description = "Transport protocol";
          };
          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Open this port in the host firewall";
          };
        };
      }
    );
  };

  # Ports known fleet-wide: either universal (ssh/http/https) or referenced
  # by multiple hosts (e.g. hetznix01 references photon to configure Dawarich).
  # openFirewall is false by default; each host's ports.nix sets it to true
  # for the ports that host actually exposes.
  config.genebean.ports = {
    ssh = {
      port = 22;
      openFirewall = true;
    };
    http = {
      port = 80;
      openFirewall = true;
    };
    https = {
      port = 443;
      openFirewall = true;
    };
    # nixnuc service; hetznix01 references this port for Dawarich's PHOTON_API_HOST.
    photon = {
      port = 2322;
    };
    # modules/shared/nixos/crowdsec.nix's own default (used on nixnuc,
    # hetznix01, hetznix02) - referenced from there rather than left as an
    # undocumented upstream default, so other services on those hosts can
    # avoid colliding with it.
    crowdsec-lapi = {
      port = 8080;
    };
    # Standard defaults for prometheus exporters, used on all monitored hosts.
    node-exporter = {
      port = 9100;
    };
    nginx-exporter = {
      port = 9113;
    };
    # star1's victorialogs container (star1/containers/victorialogs.nix) -
    # referenced by pigate's /logsink proxy and nixnuc's Grafana datasource,
    # so it lives here rather than any one host's own ports.nix.
    victorialogs = {
      port = 9428;
    };
  };
}
