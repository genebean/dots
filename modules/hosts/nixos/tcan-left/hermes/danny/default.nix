# Danny: the independent social-reporting agent. Watches press-room and
# the-paper only - see AGENTS.md. Not Leo's subordinate: no approval or
# relay step through Leo for Danny's own work.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  builder = import ../container-builder.nix {
    inherit inputs;
    hostPkgs = pkgs;
    hostTimeZone = config.time.timeZone;
  };
  digestPipeline = inputs.hermes-social-digest-pipeline.packages.${pkgs.stdenv.hostPlatform.system};
  forgejoUrl = "https://git.home.technicalissues.us";

  # Generated from the flake input's own source tree (not the built
  # hermes-social-digest-skill derivation - this is a fetched source, so
  # reading it at eval time is free, no IFD) rather than hand-enumerated,
  # so a file HermesSocialDigestPipeline adds to this skill later is
  # picked up automatically instead of silently never installing - the
  # exact failure mode this file already hit once with the wrong option
  # name for `skills`.
  skillRoot = "${inputs.hermes-social-digest-pipeline}/skills/hermes-social-digest-pipeline";
  digestSkillFiles = lib.listToAttrs (
    map (p: {
      # Attribute names can't carry string context (which store paths a
      # string depends on) - only the name needs stripping; `value = p`
      # below keeps the real context-bearing path so it still builds/copies
      # correctly.
      name = "skills/hermes-social-digest-pipeline/${builtins.unsafeDiscardStringContext (lib.removePrefix "${skillRoot}/" (toString p))}";
      value = p;
    }) (lib.filesystem.listFilesRecursive skillRoot)
  );

  # Jed's private recipient profile (hermes-agent-fleet-plan issue 36,
  # private-flake PR #14) - a Hiera-style data output, not a NixOS
  # module. Lands at HERMES_HOME's top level, read directly by the
  # daily-report-skill (issue 41). Never logged, never quoted verbatim
  # into a published report - see that skill's own instructions.
  recipientProfileFiles = {
    "recipient-profile.yaml" = inputs.private-flake.data.hermes.danny.recipientProfile;
  };

  # Same recursive-listing approach as digestSkillFiles above, for the
  # same reason - a template/reference file added to this skill later
  # (e.g. the HTML report template) gets picked up automatically.
  dailyReportSkillRoot = toString ./daily-report-skill;
  dailyReportSkillFiles = lib.listToAttrs (
    map (p: {
      name = "skills/daily-social-report/${builtins.unsafeDiscardStringContext (lib.removePrefix "${dailyReportSkillRoot}/" (toString p))}";
      value = p;
    }) (lib.filesystem.listFilesRecursive ./daily-report-skill)
  );

  # Same pattern again, for the file-newspaper-article skill.
  newspaperArticleSkillRoot = toString ./newspaper-article-skill;
  newspaperArticleSkillFiles = lib.listToAttrs (
    map (p: {
      name = "skills/file-newspaper-article/${builtins.unsafeDiscardStringContext (lib.removePrefix "${newspaperArticleSkillRoot}/" (toString p))}";
      value = p;
    }) (lib.filesystem.listFilesRecursive ./newspaper-article-skill)
  );
in
{
  imports = [
    (builder {
      name = "danny";
      soulFile = ./SOUL.md;
      agentsFile = ./AGENTS.md;
      stateHostPath = "/var/lib/hermes-containers/danny";
      stateVersion = "26.05";

      secretBindMounts = {
        "/run/secrets/hermes_danny_buzz_identity" = {
          hostPath = config.sops.secrets.hermes_danny_buzz_identity.path;
          isReadOnly = true;
        };
        "/run/secrets/hermes_danny_forgejo_token" = {
          hostPath = config.sops.secrets.hermes_danny_forgejo_token.path;
          isReadOnly = true;
        };
        "/run/secrets/hermes_danny_mcp_token" = {
          hostPath = config.sops.secrets.hermes_danny_mcp_token.path;
          isReadOnly = true;
        };
        # Reshapes the bare hermes_danny_mcp_token value (shared, as-is,
        # with nixnuc's own social-reader-mcp secret) into a KEY=value line
        # via sops.templates below, so it can land in hermes-agent's own
        # .env instead of touching the shared secret's format. hermes-agent
        # resolves a literal "${VAR}" in an mcpServers.*.headers value from
        # its own process env at MCP-connect time (tools/mcp_tool_config.py
        # _interpolate_env_vars, confirmed against the locked flake source)
        # - never from the Nix store, and it fails closed (raises) if the
        # var isn't set, rather than sending an unresolved placeholder.
        "/run/secrets/danny-mcp-http-token" = {
          hostPath = config.sops.templates."danny-mcp-http-token".path;
          isReadOnly = true;
        };
      };
      environmentFiles = [
        "/run/secrets/hermes_danny_buzz_identity"
        "/run/secrets/hermes_danny_mcp_token"
        "/run/secrets/danny-mcp-http-token"
      ];

      environment = {
        # Not a secret - matches HermesSocialDigestPipeline's own SKILL.md
        # env convention, for manual/ad-hoc `hermes-social-digest-collect`
        # invocations inside the agent's own shell. The actual scheduled
        # collect/compile-context systemd units (./social-digest.nix) use
        # the module's own `mcp.url` option instead, not this env var.
        SOCIAL_READER_MCP_URL = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
      };

      extraPackages = [
        digestPipeline.hermes-social-digest-pipeline
        pkgs.git
        pkgs.tea
      ];

      # container-builder.nix's ProtectSystem=strict makes any unlisted
      # path invisible to hermes-agent.service, not just read-only - the
      # compiled social-digest context (./social-digest.nix writes it)
      # lives outside /var/lib/hermes, so the daily-social-report skill
      # couldn't actually see it without this. Confirmed live: two
      # consecutive days of "file was missing" reports even though the
      # file demonstrably existed and was readable well before each run -
      # not a timing race, the agent process genuinely couldn't see the
      # path at all.
      extraReadOnlyPaths = [
        # Reads the pipeline module's own stateDirectoryName option
        # (containers.danny.config, set below via ./social-digest.nix)
        # rather than repeating the literal path - the module already
        # builds its own SOCIAL_DIGEST_STATE_DIR env var the same way.
        "/var/lib/${config.containers.danny.config.services.hermes-social-digest-collect.stateDirectoryName}"
      ];

      # Materializes: HermesSocialDigestPipeline's own operational-runbook
      # skill (bundled-skills directory convention, confirmed this locked
      # hermes-agent revision - flake.lock rev 9a71d5a8 - has no
      # declarative `skills` Nix option at all); Jed's private recipient
      # profile (issue 36/41); Danny's own daily-report-generation skill
      # (issue 41); and his file-newspaper-article skill, for turning a
      # published report into a genebean/newspaper PR. hermesHomeFiles is
      # the real file-materialization option here, unlike the free-form
      # hermesSettings blob.
      extraHermesHomeFiles =
        digestSkillFiles // recipientProfileFiles // dailyReportSkillFiles // newspaperArticleSkillFiles;

      hermesSettings = {
        model = {
          default = "gpt-5.6-sol"; # matches Leo's / Charlie's existing choice
          provider = "codex";
        };
        gateway.platforms.buzz.extra = {
          channels = [
            "a100215b-9a61-4e58-b8bf-47542cd20b78" # press-room
            "381f80a4-7398-47a5-ac60-78401a73e1a8" # the-paper
            "4c1462b1-fc3b-4567-9b43-5f5e75e11635" # news-editors
          ];
          home_channel = "381f80a4-7398-47a5-ac60-78401a73e1a8"; # the-paper
          # require_mention stays at the shared default (true,
          # container-builder.nix) - Danny only activates on an explicit
          # @-mention or a reply to his own message.
        };
      };
    })
  ];

  # Deterministic social collection/compilation (issue 40) and the 6am
  # daily-report cron registration/trigger (issue 41) - dedicated files,
  # same reason nixnuc's own collector got one: self-contained
  # functionality, not Danny's own agent identity. Imported into the
  # CONTAINER's nested module system (not the host's), alongside the
  # pipeline's own NixOS module, which the container doesn't otherwise
  # import.
  # Reshapes hermes_danny_mcp_token (a bare bearer-token value, shared as-is
  # with nixnuc's own social-reader-mcp secret - see the sops.secrets
  # comment above) into a KEY=value line, decrypted straight to a file
  # outside the Nix store (sops-nix's own activation-time render, same
  # mechanism nixnuc/newspaper.nix already uses for its webhook token) -
  # never duplicates the secret's encrypted value, just its on-disk shape.
  # Bind-mounted into Danny's container and merged into hermes-agent's own
  # .env below (secretBindMounts/environmentFiles above), so the mcpServers
  # block's "${SOCIAL_READER_MCP_HTTP_TOKEN}" reference resolves against
  # the interactive agent's real process env, not a Nix-store literal.
  sops.templates."danny-mcp-http-token" = {
    content = "SOCIAL_READER_MCP_HTTP_TOKEN=${config.sops.placeholder.hermes_danny_mcp_token}";
    restartUnits = [ "container@danny.service" ];
  };

  # Everything that reaches directly into the CONTAINER's own nested module
  # system (not the host's) lives in this one block - statix flags repeated
  # top-level `containers.danny.config.*` keys as separate assignments, and
  # this repo's own convention folds siblings under one parent (see
  # feedback_nix_attrset_ordering in this user's Claude memory).
  containers.danny.config = {
    # Deterministic social collection/compilation (issue 40) and the 6am
    # daily-report cron registration/trigger (issue 41) - dedicated files,
    # same reason nixnuc's own collector got one: self-contained
    # functionality, not Danny's own agent identity. The pipeline's own
    # NixOS module isn't otherwise imported by the container.
    imports = [
      inputs.hermes-social-digest-pipeline.nixosModules.default
      ./social-digest.nix
      ./daily-report-cron.nix
    ];

    # Narrow, point-lookup-only follow-up tool access (hermes-agent-fleet-
    # plan issue 34/agents-beads-collaboration-4vm) - lets Danny resolve a
    # collected candidate's thread context on demand (e.g. in #news-editors
    # follow-up) rather than only at original-collection time.
    # `tools.include` is an allowlist: nothing else social-reader-mcp
    # exposes is reachable by name from this container, even if the server
    # adds more tools later. Not a new container-builder.nix parameter -
    # matches that file's own "promote once a second call site needs it"
    # philosophy.
    services.hermes-agent.mcpServers.social-reader = {
      url = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
      # Literal "${VAR}" - resolved by hermes-agent at MCP-connect time from
      # its own process env (populated by environmentFiles above), never by
      # Nix. See the sops.templates comment above for why this var exists.
      headers.Authorization = "Bearer \${SOCIAL_READER_MCP_HTTP_TOKEN}";
      tools.include = [
        "mastodon_status_context"
        "bluesky_post_thread"
        "nostr_get_event"
        "nostr_get_events"
      ];
    };

    # Same tea-login-setup shape as Charlie's (and C.J.'s - cj/default.nix),
    # but idempotent from the start: always delete-then-add rather than
    # gating on the config file already existing. Charlie's version has the
    # opposite, known-broken shape (hermes-agent-fleet-plan#51) - a secret
    # rotation silently has no effect once the file exists once. No reason
    # to copy that bug into a third identity.
    systemd.services.tea-login-setup = {
      description = "Register Danny's Forgejo token with tea (idempotent)";
      wantedBy = [ "multi-user.target" ];
      before = [ "hermes-agent.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        secret_file=/run/secrets/hermes_danny_forgejo_token
        token=$(sed -n 's/^FORGEJO_TOKEN=//p' "$secret_file")
        if [ -z "$token" ]; then
          token=$(cat "$secret_file")
        fi
        HOME=/var/lib/hermes ${pkgs.tea}/bin/tea logins delete --name forgejo 2>/dev/null || true
        HOME=/var/lib/hermes ${pkgs.tea}/bin/tea logins add \
          --name forgejo --url ${forgejoUrl} --token "$token" --no-version-check
        chown -R hermes:hermes /var/lib/hermes/.config
      '';
    };
  };
}
