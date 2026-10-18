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
  ...
}:
let
  digestPipeline = inputs.hermes-social-digest-pipeline.packages.${pkgs.stdenv.hostPlatform.system};
  collectCfg = config.services.hermes-social-digest-collect;
  stateDir = "/var/lib/${collectCfg.stateDirectoryName}";
in
{
  # time.timeZone is set fleet-wide for every agent container via
  # hermes-agents.nix's hostTimeZone (pulled from this same host's own
  # config.time.timeZone) - not repeated here.

  # Per-NixOS-evaluation, not shared via privateNetwork=false - this is
  # the only copy now (not duplicated on the bare host, since only this
  # container actually talks to the MCP).
  networking.hosts = {
    "192.168.20.190" = [ "social-reader-mcp.home.technicalissues.us" ];
  };

  services.hermes-social-digest-collect = {
    enable = true;
    # -envfile, not the bare secret - hermes_danny_mcp_token's raw sops
    # value is "SOCIAL_READER_MCP_HTTP_TOKEN=<token>" (this repo's
    # standing convention: every env-destined secret is stored KEY=value
    # shaped, not bare). hermes-agents.nix's envFileAs mechanism wraps
    # that into a second "KEY=" layer whose own KEY= gets stripped again
    # by the final EnvironmentFile=/dotenv parse, leaving the resolved
    # env var equal to the raw value unchanged - and nixnuc's own
    # social_reader_mcp_env template does the identical wrapping, so the
    # two sides only agree when both go through it. Pointing straight at
    # the bare /run/secrets/hermes_danny_mcp_token here (confirmed live,
    # 2026-10-18) skips that wrapping, so systemd parses the raw
    # "KEY=value" file itself and resolves to the bare value instead -
    # silently mismatching nixnuc's wrapped expectation on every
    # request. This was never updated when hermes-agents.nix's envFileAs
    # convention was introduced for hermes_danny_mcp_token.
    environmentFile = "/run/secrets/hermes_danny_mcp_token-envfile";
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
      # Permission-fight history, now abandoned in favor of relocating the
      # output instead (see compile-context below): HermesSocialDigestPipeline's
      # own module leaves StateDirectoryMode at systemd's 0700 default on
      # both hermes-social-digest-collect and hermes-social-digest-catchup.
      # Tried overriding it with lib.mkForce "0755" on both (2026-10-08,
      # 2026-10-12) - confirmed live each time that the override briefly
      # "worked" but the live directory kept reverting to 0700 regardless,
      # including on hermes-social-digest-collect even though its override
      # had been confirmed working weeks earlier. systemd's StateDirectory
      # mode-reassertion behavior for an already-existing directory proved
      # unreliable enough in practice (genebean/dots issue #785) that it
      # wasn't worth continuing to chase - relocating the one file Danny
      # actually needs to read sidesteps the whole fight instead of trying
      # to win it.
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
          #
          # Lands under /var/lib/hermes (Danny's own state dir, already
          # fully owned/traversable by the `hermes` user) rather than
          # /var/lib/hermes-social-digest (owned by the separate
          # hermes-social-digest user/group, mode 0700) - see the services
          # comment above for why. The file itself still ends up root-owned
          # either way: StandardOutput's truncate: target is opened by
          # systemd itself before dropping to User/Group above, same as it
          # always was.
          StandardOutput = "truncate:/var/lib/hermes/latest-context.json";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          # ProtectSystem=strict makes /var/lib read-only otherwise, which
          # would silently break the StandardOutput redirect above -
          # confirmed this isn't optional, not just a theoretical risk.
          # stateDir: still needed to read collect's candidates/batches
          # output. /var/lib/hermes: the new output location.
          ReadWritePaths = [
            stateDir
            "/var/lib/hermes"
          ];
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
