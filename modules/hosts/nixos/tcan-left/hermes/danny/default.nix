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
        "/run/secrets/hermes_danny_mcp_token" = {
          hostPath = config.sops.secrets.hermes_danny_mcp_token.path;
          isReadOnly = true;
        };
      };
      environmentFiles = [
        "/run/secrets/hermes_danny_buzz_identity"
        "/run/secrets/hermes_danny_mcp_token"
      ];

      environment = {
        # Not a secret - matches HermesSocialDigestPipeline's own SKILL.md
        # env convention, for manual/ad-hoc `hermes-social-digest-collect`
        # invocations inside the agent's own shell. The actual scheduled
        # collect/compile-context systemd units (./social-digest.nix) use
        # the module's own `mcp.url` option instead, not this env var.
        SOCIAL_READER_MCP_URL = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
      };

      extraPackages = [ digestPipeline.hermes-social-digest-pipeline ];

      # Materializes: HermesSocialDigestPipeline's own operational-runbook
      # skill (bundled-skills directory convention, confirmed this locked
      # hermes-agent revision - flake.lock rev 9a71d5a8 - has no
      # declarative `skills` Nix option at all); Jed's private recipient
      # profile (issue 36/41); and Danny's own daily-report-generation
      # skill (issue 41). hermesHomeFiles is the real file-materialization
      # option here, unlike the free-form hermesSettings blob.
      extraHermesHomeFiles = digestSkillFiles // recipientProfileFiles // dailyReportSkillFiles;

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
  containers.danny.config.imports = [
    inputs.hermes-social-digest-pipeline.nixosModules.default
    ./social-digest.nix
    ./daily-report-cron.nix
  ];
}
