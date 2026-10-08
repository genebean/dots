# Deterministic social collection/compilation, moved here from nixnuc
# (hermes-agent-fleet-plan issue 40). Collection is a real declarative
# option from HermesSocialDigestPipeline's own NixOS module; compile-context
# has no module/service option at all (confirmed against the locked rev -
# the flake only exports one NixOS module, and "compile-context" as a
# package is just an alias for the same umbrella binary), so it's
# hand-written below.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  digestPipeline = inputs.hermes-social-digest-pipeline.packages.${pkgs.stdenv.hostPlatform.system};
  collectCfg = config.services.hermes-social-digest-collect;
  stateDir = "/var/lib/${collectCfg.stateDirectoryName}";
in
{
  # time.timeZone is set fleet-wide for every agent container via
  # container-builder.nix's hostTimeZone parameter (pulled from this same
  # host's own config.time.timeZone) - not repeated here.

  # Per-NixOS-evaluation, not shared via privateNetwork=false - this is
  # the only copy now (not duplicated on the bare host, since only this
  # container actually talks to the MCP).
  networking.hosts = {
    "192.168.20.190" = [ "social-reader-mcp.home.technicalissues.us" ];
  };

  services.hermes-social-digest-collect = {
    enable = true;
    environmentFile = "/run/secrets/hermes_danny_mcp_token";
    mcp.url = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
    timers.collectSchedules = [
      "10:00"
      "14:00"
      "18:00"
      "22:00"
      "05:30"
    ];
    # A conditional safety net ahead of the 05:30 window - runs
    # --if-previous-hit-limit, a no-op unless an earlier batch this cycle
    # hit a rate/page cap. Retimed from the old 2am slot to 4am.
    timers.catchupSchedule = "04:00";
  };

  systemd = {
    services = {
      # HermesSocialDigestPipeline's own module leaves this service's
      # StateDirectoryMode at systemd's 0700 default, and systemd
      # reasserts that mode on every service start - not just at
      # directory creation. Confirmed live (2026-10-08): a tmpfiles
      # `d 0755` rule here looked like it should keep
      # /var/lib/hermes-social-digest traversable for Danny's own
      # `hermes` user, and did, briefly, right after each boot - but the
      # collect timer fires 5x/day (10:00/14:00/18:00/22:00/05:30 plus a
      # 04:00 catchup), and the very next run silently re-clamped the
      # directory back to 0700, well before Danny's 6am report ever read
      # it. Two reset sources fighting over one directory, one of them
      # winning by a wide margin. Overriding the mode at its actual
      # source (here) removes the fight entirely - the tmpfiles rule
      # this replaced is gone, not left behind as dead weight.
      hermes-social-digest-collect.serviceConfig.StateDirectoryMode = "0755";

      hermes-social-digest-compile-context = {
        description = "Compile cached social-digest candidates into bounded context";
        serviceConfig = {
          Type = "oneshot";
          # Same user collect writes as - needs read access to its state dir.
          User = collectCfg.user;
          Group = collectCfg.group;
          Environment = "SOCIAL_DIGEST_STATE_DIR=${stateDir}";
          ExecStart = "${digestPipeline.hermes-social-digest-pipeline}/bin/hermes-social-digest-compile-context --since-hours 24 --max-candidates 250";
          # truncate:, not file: - file: opens without truncating, so a
          # shorter run leaves stale trailing bytes from the previous one.
          # Danny's 6am skill reads this as a plain file (hermes-agent-fleet-plan
          # issue 41) rather than scraping journalctl.
          StandardOutput = "truncate:${stateDir}/latest-context.json";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          # ProtectSystem=strict makes /var/lib read-only otherwise, which
          # would silently break the StandardOutput redirect above.
          ReadWritePaths = [ stateDir ];
        };
      };
    };
    timers.hermes-social-digest-compile-context = {
      description = "Run social-digest compile-context daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "05:50";
        Persistent = true;
      };
    };
  };
}
