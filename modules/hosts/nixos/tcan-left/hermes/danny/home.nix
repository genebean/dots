# Danny: the independent social-reporting agent. Watches press-room and
# the-paper only - see AGENTS.md. Not Leo's subordinate: no approval or
# relay step through Leo for Danny's own work.
#
# This Home Manager module is registered in ../agent-names.nix and imported by
# tcan-left's mkNixosHost call - see leo/home.nix's header for why.
# Everything Danny needs, including the digest-pipeline container wiring
# and MCP access below, goes through genebean.services.hermesAgents options
# - there is no NixOS-side default.nix for Danny; modules/genebean/nixos/
# services/hermes-agents.nix turns these into the actual
# container/secrets/sops config, same as every other agent.
{
  inputs,
  pkgs,
  buzzChannels,
  ...
}:
let
  digestPipeline = inputs.hermes-social-digest-pipeline.packages.${pkgs.stdenv.hostPlatform.system};

  # Jed's private recipient profile (hermes-agent-fleet-plan issue 36,
  # private-flake PR #14) - a Hiera-style data output, not a NixOS
  # module. Lands at HERMES_HOME's top level, read directly by the
  # daily-report-skill (issue 41). Never logged, never quoted verbatim
  # into a published report - see that skill's own instructions.
  recipientProfileFiles = {
    "recipient-profile.yaml" = inputs.private-flake.data.hermes.danny.recipientProfile;
  };
in
{
  genebean.services.hermesAgents.danny = {
    stateVersion = "26.05";

    agentsFile = ./AGENTS.md;
    enableGit = true;

    environment = {
      # Not a secret - matches HermesSocialDigestPipeline's own SKILL.md
      # env convention, for manual/ad-hoc `hermes-social-digest-collect`
      # invocations inside the agent's own shell. The actual scheduled
      # collect/compile-context systemd units (./social-digest.nix) use
      # the module's own `mcp.url` option instead, not this env var.
      SOCIAL_READER_MCP_URL = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
    };

    extraContainerModules = [
      inputs.hermes-social-digest-pipeline.nixosModules.default
      ./social-digest.nix
      ./daily-report-cron.nix
    ];

    extraHermesHomeFiles = recipientProfileFiles;

    extraPackages = [ digestPipeline.hermes-social-digest-pipeline ];

    # ProtectSystem=strict (set fleet-wide in hermes-agents.nix) makes any
    # unlisted path invisible to hermes-agent.service, not just read-only -
    # the compiled social digest context (./social-digest.nix writes it)
    # lives outside /var/lib/hermes, so the daily-social-report skill
    # couldn't actually see it without this. Confirmed live: two
    # consecutive days of "file was missing" reports even though the file
    # demonstrably existed and was readable well before each run - not a
    # timing race, the agent process genuinely couldn't see the path at
    # all. Hardcoded, not read back from config.containers.danny: this is
    # HermesSocialDigestPipeline's own `stateDirectoryName` option's
    # default, and ./social-digest.nix doesn't override it - if that ever
    # changes, the daily report fails the same visible way it did before
    # this was fixed, not silently.
    extraReadOnlyPaths = [ "/var/lib/hermes-social-digest" ];

    forgejoLogin.tokenSecretName = "hermes_danny_forgejo_token";

    hermesSettings = {
      model = {
        default = "gpt-5.6-sol"; # matches Leo's / Charlie's existing choice
        provider = "codex";
      };
      gateway.platforms.buzz.extra = {
        channels = [
          buzzChannels.press-room
          buzzChannels.the-paper
          buzzChannels.news-editors
          buzzChannels.time-clock
          buzzChannels.tradecraft
        ];
        # time-clock, not the-paper: keeps shutdown-notification spam
        # out of the channels people actually read, fleet-wide (2026-10-17).
        home_channel = buzzChannels.time-clock;
        # require_mention stays at the shared default (true,
        # hermes-agents.nix) - Danny only activates on an explicit
        # @-mention or a reply to his own message.
      };
    };

    managedSkills = {
      # Bundled-skills directory convention (confirmed this locked
      # hermes-agent revision has no declarative `skills` Nix option at
      # all) - generated from the flake input's own source tree, so a
      # file HermesSocialDigestPipeline adds later is picked up
      # automatically.
      daily-social-report.source = ./daily-report-skill;
      file-newspaper-article.source = ./newspaper-article-skill;
      # When this flake input bumps upstream, the new version lands in
      # the read-only /etc/hermes-skills/ reference as usual, and the
      # next weekly reconciliation run surfaces the resulting gap
      # against Danny's copy like any other official-source change - no
      # special handling needed for the flake-sourced case.
      hermes-social-digest-pipeline.source = "${inputs.hermes-social-digest-pipeline}/skills/hermes-social-digest-pipeline";
      # Adopted 2026-10-17 from Danny's own self-audit
      # (agents-beads-collaboration-62h's rules-file-reconciliation
      # discovery step) - both were self-authored, already relied on in
      # daily production use (the PR-revision and manual-rerun/recovery
      # paths for the morning report), and recommended "Adopt" on review.
      # Kept Danny-specific rather than moved into genebean/'s shared
      # namespace: both are scoped to this agent's own daily-social-
      # report/newspaper-filing workflow, not generically reusable.
      newspaper-editorial-review.source = ./newspaper-editorial-review-skill;
      social-report-delivery.source = ./social-report-delivery-skill;
    };

    # Narrow, point-lookup-only follow-up tool access. `tools.include` is
    # an allowlist: nothing else social-reader-mcp exposes is reachable by
    # name from this container, even if the server adds more tools later.
    mcpServers.social-reader = {
      url = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
      # Literal "${VAR}" - resolved by hermes-agent at MCP-connect time
      # from its own process env (populated by the envFileAs secret
      # above), never by Nix.
      headers.Authorization = "Bearer \${SOCIAL_READER_MCP_HTTP_TOKEN}";
      tools.include = [
        "mastodon_status_context"
        "bluesky_post_thread"
        "nostr_get_event"
        "nostr_get_events"
      ];
    };

    secrets = {
      hermes_danny_buzz_identity.toEnvironmentFile = true;
      hermes_danny_forgejo_token = { };
      # NOT toEnvironmentFile - this is a bare token value (shared as-is
      # with nixnuc's own social-reader-mcp secret), consumed directly by
      # services.hermes-social-digest-collect's own environmentFile option
      # (./social-digest.nix), not hermes-agent's .env. envFileAs reshapes
      # it into SOCIAL_READER_MCP_HTTP_TOKEN=<value> for hermes-agent's own
      # env instead, so the mcpServers.social-reader header above can
      # resolve it.
      hermes_danny_mcp_token.envFileAs = "SOCIAL_READER_MCP_HTTP_TOKEN";
    };

    sharedSkills = [
      "buzz-multipart-delivery"
      "newspaper-access"
      # Originated as an ad hoc skill Danny generated himself out of a
      # Buzz conversation (not hand-authored by Jed despite the
      # frontmatter's `author` field, and not Nix-managed at all until
      # 2026-10-17) - reviewed and adopted because its guidance is
      # fleet-wide generic (orchestration/delivery-verification for any
      # scheduled publication job), not Danny-specific.
      "scheduled-publication-workflows"
    ];

    soulFile = ./SOUL.md;
  };
}
