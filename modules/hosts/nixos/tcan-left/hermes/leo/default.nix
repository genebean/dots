# Leo: the coordinator. Holds only its own Buzz identity - no Forgejo
# credential, no GitHub credential. Dispatches Forgejo planning work to
# Charlie over Buzz (senior-staff channel) rather than holding that
# credential itself - see AGENTS.md.
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
    hostTimeZone = config.time.timeZone;
  };
in
builder {
  name = "leo";
  soulFile = ./SOUL.md;
  agentsFile = ./AGENTS.md;
  stateHostPath = "/var/lib/hermes-containers/leo";
  stateVersion = "26.05";

  secretBindMounts."/run/secrets/hermes_leo_buzz_identity" = {
    hostPath = config.sops.secrets.hermes_leo_buzz_identity.path;
    isReadOnly = true;
  };
  environmentFiles = [ "/run/secrets/hermes_leo_buzz_identity" ];

  hermesSettings = {
    model = {
      default = "gpt-5.6-sol"; # matches gene-personal's existing choice
      provider = "codex";
    };
    gateway.platforms.buzz.extra = {
      channels = [
        "3abc3d5f-9460-41d8-a26a-e9b50abf7da2" # senior-staff
        "a100215b-9a61-4e58-b8bf-47542cd20b78" # press-room
        "8a05dee5-ad45-4492-a68c-d5497be47a1f" # oval-office
      ];
      home_channel = "8a05dee5-ad45-4492-a68c-d5497be47a1f"; # oval-office
      # Leo is the primary conversational partner - he should respond to
      # any message in his channels without needing an @-mention every
      # time. Every subordinate keeps the shared require_mention = true
      # default (container-builder.nix) so they stay quiet unless addressed.
      require_mention = false;
    };
  };
}
