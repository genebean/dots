# C.J.: the press secretary. Delivers official briefings in #press-room,
# compiled by Leo and approved by Jed - see AGENTS.md. Holds no publishing
# credential of her own; reporters (Danny, et al.) publish what's said in
# the briefing room, she doesn't.
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
  name = "cj";
  soulFile = ./SOUL.md;
  agentsFile = ./AGENTS.md;
  stateHostPath = "/var/lib/hermes-containers/cj";
  stateVersion = "26.05";

  secretBindMounts."/run/secrets/hermes_cj_buzz_identity" = {
    hostPath = config.sops.secrets.hermes_cj_buzz_identity.path;
    isReadOnly = true;
  };
  environmentFiles = [ "/run/secrets/hermes_cj_buzz_identity" ];

  hermesSettings = {
    model = {
      default = "gpt-5.6-sol"; # matches the rest of the fleet
      provider = "codex";
    };
    gateway.platforms.buzz.extra = {
      channels = [
        "3abc3d5f-9460-41d8-a26a-e9b50abf7da2" # senior-staff
        "a100215b-9a61-4e58-b8bf-47542cd20b78" # press-room
      ];
      home_channel = "a100215b-9a61-4e58-b8bf-47542cd20b78"; # press-room
      # require_mention stays at the shared default (true,
      # container-builder.nix) - C.J. only delivers on direction, same as
      # Charlie/Danny, not a primary conversational partner like Leo.
    };
  };
}
