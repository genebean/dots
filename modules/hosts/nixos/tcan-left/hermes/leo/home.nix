# Leo: the coordinator. Holds only its own Buzz identity - no Forgejo
# credential, no GitHub credential. Dispatches Forgejo planning work to
# Charlie over Buzz (senior-staff channel) rather than holding that
# credential itself - see AGENTS.md.
#
# This Home Manager module is registered in ../agent-names.nix and imported by
# tcan-left's mkNixosHost call. The real genebean.services.hermesAgents
# option lives on the home side (modules/genebean/home/services/
# hermes-agents.nix), per this repo's own convention
# (modules/genebean/README.md). The NixOS companion reads this resolved
# value back and does the actual system-level work (container, secrets,
# etc.).
{ buzzChannels, ... }:
{
  genebean.services.hermesAgents.leo = {
    stateVersion = "26.05";

    agentsFile = ./AGENTS.md;

    hermesSettings = {
      model = {
        default = "gpt-5.6-sol"; # matches gene-personal's existing choice
        provider = "codex";
      };
      gateway.platforms.buzz.extra = {
        channels = [
          buzzChannels.senior-staff
          buzzChannels.press-room
          buzzChannels.oval-office
          buzzChannels.time-clock
          buzzChannels.tradecraft
        ];
        # time-clock, not oval-office: keeps shutdown-notification spam
        # out of the channels people actually read, fleet-wide (2026-10-17).
        home_channel = buzzChannels.time-clock;
        # Was false (Leo as always-listening primary conversational partner)
        # - reverted to the shared require_mention = true default
        # (hermes-agents.nix) after he was found responding to messages
        # that weren't actually addressed to him. No override needed; this
        # line exists only to document that the choice was deliberate, not
        # an oversight.
        require_mention = true;
      };
    };

    # Staggered 1hr apart from the rest of the fleet's own reconciliation
    # sessions (Thursdays, Danny last at the default 17:00) so they don't
    # all race each other - see hermes-agents.nix's own option doc.
    reconciliationSchedule = "0 15 * * 4";

    secrets.hermes_leo_buzz_identity.toEnvironmentFile = true;

    sharedSkills = [ "newspaper-access" ];

    soulFile = ./SOUL.md;
  };
}
