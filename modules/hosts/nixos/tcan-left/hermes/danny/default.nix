# Danny: the independent social-reporting agent. Watches press-room and
# the-paper only - see AGENTS.md. Not Leo's subordinate: no approval or
# relay step through Leo for Danny's own work.
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  builder = import ../container-builder.nix {
    inherit inputs;
    hostPkgs = pkgs;
  };
  digestPipeline = inputs.hermes-social-digest-pipeline.packages.${pkgs.system};
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
        # env convention. hermes-agent-fleet-plan issue 40 wires the actual
        # collect/compile systemd units that read this.
        SOCIAL_READER_MCP_URL = "https://social-reader-mcp.home.technicalissues.us:8443/mcp";
      };

      extraPackages = [ digestPipeline.hermes-social-digest-pipeline ];

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
    })
  ];

  # This locked hermes-agent revision (flake.lock rev 9a71d5a8) has no
  # declarative `skills` option at all - confirmed directly against the
  # evaluated module (`services.hermes-agent.skills` doesn't exist here,
  # unlike a newer upstream revision). hermesHomeFiles is the real,
  # existing mechanism (already used for SOUL.md inside container-builder.nix,
  # landing at ${stateDir}/.hermes/SOUL.md) - mirrored here per-file to
  # materialize HermesSocialDigestPipeline's own operational-runbook skill
  # at ${stateDir}/.hermes/skills/hermes-social-digest-pipeline/, matching
  # the bundled-skills directory convention already observed at that same
  # path. Not yet wired into any schedule (issue 40's job) - just present
  # and ready. Set outside the builder call, same reason Charlie's
  # tea-login-setup oneshot lives outside it too.
  containers.danny.config.services.hermes-agent.hermesHomeFiles = {
    "skills/hermes-social-digest-pipeline/SKILL.md" =
      "${digestPipeline.hermes-social-digest-skill}/share/hermes/skills/hermes-social-digest-pipeline/SKILL.md";
    "skills/hermes-social-digest-pipeline/references/cron-setup.md" =
      "${digestPipeline.hermes-social-digest-skill}/share/hermes/skills/hermes-social-digest-pipeline/references/cron-setup.md";
    "skills/hermes-social-digest-pipeline/references/lan-mcp-configuration.md" =
      "${digestPipeline.hermes-social-digest-skill}/share/hermes/skills/hermes-social-digest-pipeline/references/lan-mcp-configuration.md";
  };
}
