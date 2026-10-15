# Leo: the coordinator. Holds only its own Buzz identity - no Forgejo
# credential, no GitHub credential. Dispatches Forgejo planning work to
# Charlie over Buzz (senior-staff channel) rather than holding that
# credential itself - see AGENTS.md.
#
# This is a Home Manager module (imported via tcan-left/home-gene.nix ->
# ./hermes/home.nix) - the real genebean.services.hermesAgents option lives
# on the home side (modules/genebean/home/services/hermes-agents.nix), per
# this repo's own convention (modules/genebean/README.md). The NixOS
# companion reads this resolved value back and does the actual system-level
# work (container, secrets, etc.) - see modules/genebean/nixos/services/
# hermes-agents.nix.
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
          buzzChannels.tradecraft
        ];
        home_channel = buzzChannels.oval-office;
        # Was false (Leo as always-listening primary conversational partner)
        # - reverted to the shared require_mention = true default
        # (hermes-agents.nix) after he was found responding to messages
        # that weren't actually addressed to him. No override needed; this
        # line exists only to document that the choice was deliberate, not
        # an oversight.
        require_mention = true;
      };
    };

    secrets.hermes_leo_buzz_identity.toEnvironmentFile = true;

    soulFile = ./SOUL.md;
  };
}
