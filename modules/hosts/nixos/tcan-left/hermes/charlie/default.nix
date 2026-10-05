# Charlie: the Forgejo-scoped planning worker. Watches only senior-staff.
# Any relay member can technically message it (BUZZ_ALLOW_ALL_USERS, the
# shared container-builder.nix default) - the "only act on Leo's
# instructions" rule is judgment enforced in AGENTS.md, not a technical
# allow-list.
#
# Forgejo access is via `tea` (Gitea's official CLI, pkgs.tea), run through
# Charlie's own generic terminal tool - not an MCP server. No bundled or
# trustworthy third-party Forgejo/Gitea MCP server exists, so `tea` avoids
# an extra unmaintained-dependency risk for no real benefit; this is the
# same tool already proven working for this exact repo earlier this session.
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
  forgejoUrl = "https://git.home.technicalissues.us";
in
{
  imports = [
    (builder {
      name = "charlie";
      soulFile = ./SOUL.md;
      agentsFile = ./AGENTS.md;
      stateHostPath = "/var/lib/hermes-containers/charlie";
      stateVersion = "26.05";

      secretBindMounts = {
        "/run/secrets/hermes_charlie_buzz_identity" = {
          hostPath = config.sops.secrets.hermes_charlie_buzz_identity.path;
          isReadOnly = true;
        };
        "/run/secrets/hermes_charlie_forgejo_token" = {
          hostPath = config.sops.secrets.hermes_charlie_forgejo_token.path;
          isReadOnly = true;
        };
      };
      environmentFiles = [
        "/run/secrets/hermes_charlie_buzz_identity"
        # NOT handed to hermes-agent's own environment - tea needs a
        # persisted login (tea-login-setup below), not a live env var per
        # call. Still bind-mounted above so that setup unit can read it.
      ];

      extraPackages = [ pkgs.tea ];

      hermesSettings = {
        model = {
          default = "gpt-5.6-sol"; # matches Leo's / gene-personal's existing choice
          provider = "codex";
        };
        gateway.platforms.buzz.extra = {
          channels = [
            "3abc3d5f-9460-41d8-a26a-e9b50abf7da2" # senior-staff
          ];
          home_channel = "3abc3d5f-9460-41d8-a26a-e9b50abf7da2"; # senior-staff
          # require_mention stays at the shared default (true,
          # container-builder.nix) - Charlie only activates on an explicit
          # @-mention or a reply to its own message, so Leo's own channel
          # chatter doesn't wake it unprompted.
        };
      };
    })
  ];

  # tea has no per-command --token override (confirmed from `tea --help`/
  # `tea logins add --help`) - it needs a login persisted to
  # ~/.config/tea/config.yml once, not a live env var fed on every call.
  # This oneshot registers that login from the bind-mounted secret before
  # hermes-agent ever starts, and is a no-op on every later activation once
  # the config file already exists.
  #
  # Secret format expected: a single `FORGEJO_TOKEN=<value>` line, matching
  # the same convention as the Buzz identity secrets - confirm this when
  # migrating hermes_charlie_forgejo_token into modules/shared/secrets.yaml
  # (task #23), since its original format predates this convention.
  containers.charlie.config.systemd.services.tea-login-setup = {
    description = "Register Charlie's Forgejo token with tea (one-time)";
    wantedBy = [ "multi-user.target" ];
    before = [ "hermes-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Runs as root, not "hermes": the bind-mounted secret is root:root
      # 0400 on the host side (sops-nix default), and there's no "hermes"
      # user on the bare host anymore for a numeric UID to even line up
      # with - root is the one identity guaranteed to read it regardless.
      # The config file this writes gets explicitly chowned to "hermes" by
      # NAME below, resolved against the container's own /etc/passwd.
    };
    script = ''
      set -euo pipefail
      config_file="/var/lib/hermes/.config/tea/config.yml"
      if [ -e "$config_file" ]; then
        exit 0
      fi
      secret_file=/run/secrets/hermes_charlie_forgejo_token
      # Tolerate either a `FORGEJO_TOKEN=<value>` line (matching the Buzz
      # identity secrets' convention) or the bare token as the file's whole
      # content - whichever this secret was actually set as. Never read
      # this script's own output to check which one it is.
      token=$(sed -n 's/^FORGEJO_TOKEN=//p' "$secret_file")
      if [ -z "$token" ]; then
        token=$(cat "$secret_file")
      fi
      HOME=/var/lib/hermes ${pkgs.tea}/bin/tea logins add \
        --name forgejo --url ${forgejoUrl} --token "$token" --no-version-check
      chown -R hermes:hermes /var/lib/hermes/.config
    '';
  };
}
