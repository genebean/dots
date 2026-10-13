# C.J.: the press secretary. Delivers official briefings in #press-room,
# compiled by Leo and approved by Jed - see AGENTS.md. Holds a Forgejo
# credential scoped to her own two record types (official-statement,
# official-briefing) on genebean/newspaper - separate from Danny's, whose
# own credential is scoped to his (independent-reporting). Real-world
# press/government separation: the administration publishes its own
# record, the reporter publishes theirs, neither through the other.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  builder = import ../container-builder.nix {
    inherit inputs;
    hostPkgs = pkgs;
    hostTimeZone = config.time.timeZone;
  };
  forgejoUrl = "https://git.home.technicalissues.us";

  # Same recursive-listing approach as Danny's own skill materialization
  # (danny/default.nix) - a file added to this skill later gets picked up
  # automatically, no Nix change needed.
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
      name = "cj";
      soulFile = ./SOUL.md;
      agentsFile = ./AGENTS.md;
      stateHostPath = "/var/lib/hermes-containers/cj";
      stateVersion = "26.05";

      secretBindMounts = {
        "/run/secrets/hermes_cj_buzz_identity" = {
          hostPath = config.sops.secrets.hermes_cj_buzz_identity.path;
          isReadOnly = true;
        };
        "/run/secrets/hermes_cj_forgejo_token" = {
          hostPath = config.sops.secrets.hermes_cj_forgejo_token.path;
          isReadOnly = true;
        };
      };
      environmentFiles = [ "/run/secrets/hermes_cj_buzz_identity" ];
      extraPackages = [
        pkgs.git
        pkgs.tea
      ];
      # Materializes C.J.'s file-newspaper-article skill, for turning an
      # already-approved briefing or statement into a genebean/newspaper
      # PR. hermesHomeFiles is the real file-materialization option here,
      # unlike the free-form hermesSettings blob.
      extraHermesHomeFiles = newspaperArticleSkillFiles;

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
          home_channel = "3abc3d5f-9460-41d8-a26a-e9b50abf7da2"; # senior-staff
          # require_mention stays at the shared default (true,
          # container-builder.nix) - C.J. only delivers on direction, same
          # as Charlie/Danny, not a primary conversational partner like Leo.
        };
      };
    })
  ];

  # Same tea-login-setup shape as Danny's (danny/default.nix) and
  # Charlie's - idempotent from the start, see Danny's copy of this
  # comment for why.
  containers.cj.config.systemd.services.tea-login-setup = {
    description = "Register C.J.'s Forgejo token with tea (idempotent)";
    wantedBy = [ "multi-user.target" ];
    before = [ "hermes-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      secret_file=/run/secrets/hermes_cj_forgejo_token
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
}
