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
  };
  digestPipeline = inputs.hermes-social-digest-pipeline.packages.${pkgs.system};

  # Generated from the flake input's own source tree (not the built
  # hermes-social-digest-skill derivation - this is a fetched source, so
  # reading it at eval time is free, no IFD) rather than hand-enumerated,
  # so a file HermesSocialDigestPipeline adds to this skill later is
  # picked up automatically instead of silently never installing - the
  # exact failure mode this file already hit once with the wrong option
  # name for `skills`.
  skillRoot = "${inputs.hermes-social-digest-pipeline}/skills/hermes-social-digest-pipeline";
  skillFiles = lib.listToAttrs (
    map (p: {
      # Attribute names can't carry string context (which store paths a
      # string depends on) - only the name needs stripping; `value = p`
      # below keeps the real context-bearing path so it still builds/copies
      # correctly.
      name = "skills/hermes-social-digest-pipeline/${builtins.unsafeDiscardStringContext (lib.removePrefix "${skillRoot}/" (toString p))}";
      value = p;
    }) (lib.filesystem.listFilesRecursive skillRoot)
  );
in
builder {
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
    # Not a secret - matches HermesSocialDigestPipeline's own SKILL.md env
    # convention. hermes-agent-fleet-plan issue 40 wires the actual
    # collect/compile systemd units that read this.
    SOCIAL_READER_MCP_URL = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
  };

  extraPackages = [ digestPipeline.hermes-social-digest-pipeline ];

  # Materializes HermesSocialDigestPipeline's own operational-runbook
  # skill at ${stateDir}/.hermes/skills/hermes-social-digest-pipeline/,
  # matching the bundled-skills directory convention already observed at
  # that same path. This locked hermes-agent revision (flake.lock rev
  # 9a71d5a8) has no declarative `skills` Nix option at all - confirmed
  # directly against the evaluated module - so hermesHomeFiles (a real
  # file-materialization option, unlike the free-form hermesSettings
  # blob) is the correct mechanism. Not yet wired into any schedule
  # (issue 40's job) - just present and ready.
  extraHermesHomeFiles = skillFiles;

  hermesSettings = {
    model = {
      default = "gpt-5.6-sol"; # matches Leo's / Charlie's existing choice
      provider = "codex";
    };
    gateway.platforms.buzz.extra = {
      channels = [
        "a100215b-9a61-4e58-b8bf-47542cd20b78" # press-room
        "381f80a4-7398-47a5-ac60-78401a73e1a8" # the-paper
      ];
      home_channel = "381f80a4-7398-47a5-ac60-78401a73e1a8"; # the-paper
      # require_mention stays at the shared default (true,
      # container-builder.nix) - Danny only activates on an explicit
      # @-mention or a reply to his own message.
    };
  };
}
