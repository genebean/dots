# Charlie: the Forgejo-scoped planning worker. Watches only senior-staff.
# Any relay member can technically message it (BUZZ_ALLOW_ALL_USERS, the
# shared hermes-agents.nix default) - the "only act on Leo's instructions"
# rule is judgment enforced in AGENTS.md, not a technical allow-list.
#
# Forgejo access is via `tea` (Gitea's official CLI), run through Charlie's
# own generic terminal tool - not an MCP server. No bundled or trustworthy
# third-party Forgejo/Gitea MCP server exists, so `tea` avoids an extra
# unmaintained-dependency risk for no real benefit.
#
# This Home Manager module is registered in ../agent-names.nix and imported by
# tcan-left's mkNixosHost call - see leo/home.nix's header for why.
{ buzzChannels, ... }:
{
  genebean.services.hermesAgents.charlie = {
    stateVersion = "26.05";

    agentsFile = ./AGENTS.md;

    # Was previously gated on the config file already existing
    # (hermes-agent-fleet-plan#51 - a credential rotation silently had no
    # effect once the file existed once). The module's forgejoLogin option
    # generates the idempotent delete-then-add shape unconditionally - this
    # migration also fixes that bug, not just removes duplication.
    forgejoLogin.tokenSecretName = "hermes_charlie_forgejo_token";

    hermesSettings = {
      model = {
        default = "gpt-5.6-sol"; # matches Leo's / gene-personal's existing choice
        provider = "codex";
      };
      gateway.platforms.buzz.extra = {
        channels = [
          buzzChannels.senior-staff
          buzzChannels.time-clock
          buzzChannels.tradecraft
        ];
        # time-clock, not senior-staff: keeps shutdown-notification spam
        # out of the channels people actually read, fleet-wide (2026-10-17).
        home_channel = buzzChannels.time-clock;
        # require_mention stays at the shared default (true,
        # hermes-agents.nix) - Charlie only activates on an explicit
        # @-mention or a reply to its own message, so Leo's own channel
        # chatter doesn't wake it unprompted.
      };
    };

    secrets = {
      hermes_charlie_buzz_identity.toEnvironmentFile = true;
      # NOT toEnvironmentFile - tea needs a persisted login (forgejoLogin
      # above), not a live env var per call.
      hermes_charlie_forgejo_token = { };
    };

    sharedSkills = [ "newspaper-access" ];

    soulFile = ./SOUL.md;
  };
}
