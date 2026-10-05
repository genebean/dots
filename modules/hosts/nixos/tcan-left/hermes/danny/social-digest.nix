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
  digestPipeline = inputs.hermes-social-digest-pipeline.packages.${pkgs.system};
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
    services.hermes-social-digest-compile-context = {
      description = "Compile cached social-digest candidates into bounded context";
      serviceConfig = {
        Type = "oneshot";
        # Same user collect writes as - needs read access to its state dir.
        User = "hermes-social-digest";
        Group = "hermes-social-digest";
        Environment = "SOCIAL_DIGEST_STATE_DIR=/var/lib/hermes-social-digest";
        ExecStart = "${digestPipeline.hermes-social-digest-pipeline}/bin/hermes-social-digest-compile-context --since-hours 24 --max-candidates 250";
        # truncate:, not file: - file: opens without truncating, so a
        # shorter run leaves stale trailing bytes from the previous one.
        # Danny's 6am skill reads this as a plain file (hermes-agent-fleet-plan
        # issue 41) rather than scraping journalctl.
        StandardOutput = "truncate:/var/lib/hermes-social-digest/latest-context.json";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        # ProtectSystem=strict makes /var/lib read-only otherwise, which
        # would silently break the StandardOutput redirect above.
        ReadWritePaths = [ "/var/lib/hermes-social-digest" ];
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
    # The collect service's own StateDirectory lands at 0700
    # hermes-social-digest:hermes-social-digest - confirmed live this
    # blocks Danny's own `hermes` user from even traversing into the
    # directory to reach latest-context.json above, regardless of that
    # file's own 0644 mode (Unix needs +x on every ancestor dir, which
    # `ls -la` as root doesn't reveal since root bypasses that check).
    # Re-opening just the top-level directory's traversal bit here, not
    # the subdirectories underneath (batches/briefings/candidates/locks
    # stay 0700 - genuinely private intermediate state, not meant for
    # the report-reading skill). tmpfiles `d` re-enforces this mode on
    # every systemd-tmpfiles-resetup run, which is what we want here.
    tmpfiles.rules = [
      "d /var/lib/hermes-social-digest 0755 hermes-social-digest hermes-social-digest -"
    ];
  };
}
