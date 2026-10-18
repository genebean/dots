# C.J.: the press secretary. Delivers official briefings in #press-room,
# compiled by Leo and approved by Jed - see AGENTS.md. Holds a Forgejo
# credential scoped to her own two record types (official-statement,
# official-briefing) on genebean/newspaper - separate from Danny's, whose
# own credential is scoped to his (independent-reporting). Real-world
# press/government separation: the administration publishes its own
# record, the reporter publishes theirs, neither through the other.
#
# This Home Manager module is registered in ../agent-names.nix and imported by
# tcan-left's mkNixosHost call - see leo/home.nix's header for why.
{ buzzChannels, ... }:
{
  genebean.services.hermesAgents.cj = {
    stateVersion = "26.05";

    agentsFile = ./AGENTS.md;
    enableGit = true;

    forgejoLogin.tokenSecretName = "hermes_cj_forgejo_token";

    hermesSettings = {
      model = {
        default = "gpt-5.6-sol"; # matches the rest of the fleet
        provider = "codex";
      };
      gateway.platforms.buzz.extra = {
        channels = [
          buzzChannels.senior-staff
          buzzChannels.press-room
          buzzChannels.time-clock
          buzzChannels.tradecraft
        ];
        # time-clock, not senior-staff: keeps shutdown-notification spam
        # out of the channels people actually read, fleet-wide (2026-10-17).
        home_channel = buzzChannels.time-clock;
        # require_mention stays at the shared default (true,
        # hermes-agents.nix) - C.J. only delivers on direction, same as
        # Charlie/Danny, not a primary conversational partner like Leo.
      };
    };

    managedSkills.file-newspaper-article.source = ./newspaper-article-skill;

    # Staggered 1hr apart from the rest of the fleet's own reconciliation
    # sessions (Thursdays, Danny last at the default 17:00) so they don't
    # all race each other - see hermes-agents.nix's own option doc.
    reconciliationSchedule = "0 14 * * 4";

    secrets = {
      hermes_cj_buzz_identity.toEnvironmentFile = true;
      hermes_cj_forgejo_token = { };
    };

    sharedSkills = [ "newspaper-access" ];

    soulFile = ./SOUL.md;
  };
}
