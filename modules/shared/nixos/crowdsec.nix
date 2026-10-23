{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # This pinned nixpkgs channel's crowdsec module has three confirmed real
  # bugs (api.server.enable defaults to false while the agent still tries
  # to act as an API client against it; crowdsec-firewall-bouncer's
  # registerBouncer script calls bare cscli assuming /etc/crowdsec/config.yaml
  # exists, which this module never creates; acquisitions option moved).
  # All three are fixed by NixOS/nixpkgs pull request 535319 (a refactor
  # sprint merged into nixpkgs-unstable 2026-10-21, not yet backported to
  # release-26.05 and unlikely to be - nixpkgs doesn't typically backport
  # refactors). Importing the fixed module files directly from
  # nixpkgs-unstable, same pattern already used for forgejo-runner.nix in
  # nixnuc/forgejo.nix. The package is pulled from the same unstable tree
  # (not this channel's crowdsec) to keep the module and binary matched -
  # same reasoning forgejo-runner.nix already applies to its own package.
  unstablePkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  # Both built-in copies declare the same option paths as the unstable
  # modules imported below (confirmed live: evaluating without this threw
  # "option ... is already declared" for crowdsec-firewall-bouncer.nix,
  # since its path is identical between channels - only the agent module
  # moved, from crowdsec.nix to crowdsec/default.nix).
  disabledModules = [
    "services/security/crowdsec-firewall-bouncer.nix"
    "services/security/crowdsec.nix"
  ];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/crowdsec/default.nix"
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/crowdsec-firewall-bouncer.nix"
  ];

  # Confirmed live: without this, building the HTML manual fails outright -
  # the unstable crowdsec module's option docs reference a release-notes
  # anchor ("sec-crowdsec-reset") that doesn't exist in this (older,
  # release-26.05) system's own manual/redirects data. A known trade-off of
  # importing a module from a different channel - these are headless
  # servers, nobody runs `nixos-help` on them, so losing the local manual
  # build is an acceptable cost for the fix.
  documentation.nixos.enable = false;

  ##########################################################################
  #                                                                        #
  #  CrowdSec, DRY-RUN ONLY - do not flip this to enforcing without       #
  #  re-reading agents-beads-collaboration-g4f first.                     #
  #                                                                        #
  #  The repo owner was burned by CrowdSec years ago: it locked out       #
  #  legitimate traffic almost immediately. The most likely cause was     #
  #  the community blocklist - bans made by OTHER people's CrowdSec       #
  #  installs, pulled in automatically via the Central API. Two           #
  #  deliberate decisions below exist specifically to not repeat that,    #
  #  both now handled natively by the module's own setup script rather    #
  #  than a custom provisioning unit:                                     #
  #                                                                        #
  #    1. config.api.server.online_client.credentials_path is left at     #
  #       its default (null) - the module's setup script only runs        #
  #       `cscli capi register` when this is set, so leaving it unset     #
  #       means this install NEVER registers with the Central API and     #
  #       never pulls the community blocklist. Local scenarios (this      #
  #       host's own logs) are the only decision source.                  #
  #    2. settings.simulation.simulation = true marks every decision as   #
  #       simulated - a compliant bouncer (crowdsec-firewall-bouncer      #
  #       below) logs what it WOULD have blocked without touching the     #
  #       firewall. Fully declarative now - the module writes this        #
  #       straight to simulation.yaml, no imperative cscli step needed.   #
  #                                                                        #
  #  Collections installed are deliberately narrow (linux, sshd, nginx)   #
  #  to match what's actually running - add more only alongside whatever  #
  #  new log source needs it.                                             #
  #                                                                        #
  #  Decisions/alerts from this dry-run live only in CrowdSec's local      #
  #  SQLite DB (`cscli decisions list` / `cscli alerts list`) until the   #
  #  planned star1 observability stack (Tempo/Loki) exists to ship them   #
  #  somewhere durable. Tracked in agents-beads-collaboration-g4f.        #
  #                                                                        #
  ##########################################################################

  services.crowdsec = {
    enable = true;
    package = unstablePkgs.crowdsec;

    hub.collections = [
      "crowdsecurity/linux"
      "crowdsecurity/nginx"
      "crowdsecurity/sshd"
    ];

    settings = {
      simulation.simulation = true;

      # Without this, crowdsec starts but reads nothing - confirmed by the
      # evaluator's own warning the first time this module was added
      # without it. Split the same way fail2ban-nginx.nix's jails had to
      # be, for the same confirmed reason: nginx's error_log defaults to
      # "stderr" (journald), while its access_log has no override and
      # falls back to the real file at /var/log/nginx/access.log.
      acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=nginx.service" ];
          labels.type = "nginx";
        }
        {
          filenames = [ "/var/log/nginx/access.log" ];
          labels.type = "nginx";
        }
      ];
    };
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    package = unstablePkgs.crowdsec-firewall-bouncer;
    # Safe to auto-register now: /etc/crowdsec/config.yaml genuinely exists
    # (the new module symlinks it unconditionally via tmpfiles), unlike the
    # pinned module this used to crash against.
    registerBouncer.enable = true;
  };
}
