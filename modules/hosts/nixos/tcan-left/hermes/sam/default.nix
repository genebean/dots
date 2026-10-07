# Sam: the GitHub product-repo worker (mylittletechbot). Forks, branches,
# commits, and opens PRs against dots and the Hermes app repos - never
# self-merges, see AGENTS.md. No private-flake access (it moved to
# Forgejo; Sam holds no Forgejo credential). Any relay member can
# technically message it (BUZZ_ALLOW_ALL_USERS, the shared
# container-builder.nix default); the "only act on Leo's instructions"
# rule is judgment enforced in AGENTS.md, not a technical allow-list -
# same shape as Charlie.
#
# GitHub App, not a PAT (hermes-agent-fleet-plan's authority-boundaries.md
# explicitly prefers this): a GitHub App's private key mints short-lived
# (1 hour) installation access tokens on demand, instead of a long-lived
# static secret sitting on the host regardless of scoping.
#
# The private key itself stays root:root 0400 (sops-nix's default) - same
# reasoning as Charlie's tea-login-setup comment: there's no "hermes" user
# on the bare host for a numeric UID to line up with, so the key's host-side
# permissions can't be loosened to match the in-container agent user
# directly. Unlike Charlie's one-time setup (a non-expiring Forgejo PAT,
# persisted once via `tea logins add`), there's no derived artifact that can
# be minted once and reused - installation tokens expire hourly. So instead
# of giving the `hermes` user any path to the raw key at all, a root-run
# systemd timer inside this container mints a fresh token on its own
# schedule and writes JUST the token (not the key) to a container-local
# tmpfs path, readable by `hermes`. `sam-gh` and the git credential helper
# below only ever read that already-minted token - the agent's own process
# never touches the App's private key.
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

  # The App's own identifier - not secret, same tier as a relay/channel ID
  # elsewhere in this file. Only the private key (sops) is sensitive.
  githubAppId = "5204628";
  githubAppKeyPath = "/run/secrets/hermes_sam_github_app_key";

  # tmpfs (/run), not persistent state - an hour-old token left over from a
  # prior boot would be stale anyway, and this way there's nothing to clean
  # up on container rebuild either.
  tokenFile = "/run/sam-github-token";

  # For `gh` CLI operations (opening PRs, reading CI results, etc.) -
  # `GH_TOKEN` takes precedence over any persisted `gh auth login`, so this
  # needs no login step at all, just the env var set fresh per call.
  samGh = pkgs.writeShellScriptBin "sam-gh" ''
    set -euo pipefail
    token=$(cat ${tokenFile})
    GH_TOKEN="$token" exec ${pkgs.gh}/bin/gh "$@"
  '';

  # For raw `git clone`/`git push` against an `https://github.com/...`
  # remote (not every git operation goes through `gh repo clone`) - a git
  # credential helper is invoked fresh by git itself on every operation
  # that needs one.
  samGitCredentialHelper = pkgs.writeShellScriptBin "sam-git-credential-helper" ''
    set -euo pipefail
    if [ "''${1:-}" != "get" ]; then
      exit 0
    fi
    token=$(cat ${tokenFile})
    echo "username=x-access-token"
    echo "password=$token"
  '';
in
{
  imports = [
    (builder {
      name = "sam";
      soulFile = ./SOUL.md;
      agentsFile = ./AGENTS.md;
      stateHostPath = "/var/lib/hermes-containers/sam";
      stateVersion = "26.05";

      secretBindMounts."${githubAppKeyPath}" = {
        hostPath = config.sops.secrets.hermes_sam_github_app_key.path;
        isReadOnly = true;
      };
      environmentFiles = [ "/run/secrets/hermes_sam_buzz_identity" ];

      secretBindMounts."/run/secrets/hermes_sam_buzz_identity" = {
        hostPath = config.sops.secrets.hermes_sam_buzz_identity.path;
        isReadOnly = true;
      };

      extraPackages = [
        pkgs.gh
        pkgs.gh-token
        pkgs.git
        pkgs.jq
        samGh
        samGitCredentialHelper
      ];

      hermesSettings = {
        model = {
          default = "gpt-5.6-sol"; # matches the rest of the fleet
          provider = "codex";
        };
        gateway.platforms.buzz.extra = {
          channels = [
            "3abc3d5f-9460-41d8-a26a-e9b50abf7da2" # senior-staff
          ];
          home_channel = "3abc3d5f-9460-41d8-a26a-e9b50abf7da2"; # senior-staff
          # require_mention stays at the shared default (true,
          # container-builder.nix) - Sam only activates on an explicit
          # @-mention or a reply to its own message, same as Charlie.
        };
      };
    })
  ];

  # Points git at the credential helper above for any github.com HTTPS
  # remote - a one-time config write, safe to persist (unlike a token
  # itself) since the helper mints fresh credentials on every git
  # operation that actually needs one. Same before/RemainAfterExit shape
  # as Charlie's tea-login-setup.
  containers.sam.config.systemd.services.git-credential-helper-setup = {
    description = "Configure Sam's git credential helper for github.com (one-time)";
    wantedBy = [ "multi-user.target" ];
    before = [ "hermes-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "hermes";
      Group = "hermes";
      Environment = "HOME=/var/lib/hermes";
    };
    script = ''
      set -euo pipefail
      ${pkgs.git}/bin/git config --global credential.helper \
        "!${samGitCredentialHelper}/bin/sam-git-credential-helper"
    '';
  };

  containers.sam.config.systemd = {
    # Root here is deliberate and the whole point: only this service ever
    # opens the raw App private key (root:root 0400, sops-nix default,
    # unchanged on the host side). It writes out only the derived, already-
    # scoped, hour-lived installation token - never the key itself - so the
    # `hermes` user (and Sam's own agent process) never gets a path to the
    # long-lived credential at all, only to tokens that are already short-
    # lived and narrowly scoped by the time they're readable.
    services.sam-github-token-refresh = {
      description = "Mint Sam's GitHub App installation token";
      wantedBy = [ "multi-user.target" ];
      before = [ "hermes-agent.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        installation_id=$(${pkgs.gh-token}/bin/gh-token installations \
          --key ${githubAppKeyPath} --app-id ${githubAppId} | ${pkgs.jq}/bin/jq -r '.[0].id')
        token=$(${pkgs.gh-token}/bin/gh-token generate \
          --key ${githubAppKeyPath} --app-id ${githubAppId} \
          --installation-id "$installation_id" | ${pkgs.jq}/bin/jq -r '.token')
        tmpfile=$(${pkgs.coreutils}/bin/mktemp ${tokenFile}.XXXXXX)
        printf '%s' "$token" > "$tmpfile"
        ${pkgs.coreutils}/bin/chown hermes:hermes "$tmpfile"
        ${pkgs.coreutils}/bin/chmod 0440 "$tmpfile"
        ${pkgs.coreutils}/bin/mv -f "$tmpfile" ${tokenFile}
      '';
    };

    # Installation tokens expire after 1 hour - refresh well ahead of that.
    # OnUnitActiveSec alone (no OnBootSec/OnCalendar) is enough: the service
    # above already guarantees a first mint at boot via `before`, and this
    # timer only needs to keep it fresh after that.
    timers.sam-github-token-refresh = {
      description = "Refresh Sam's GitHub App installation token before it expires";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnUnitActiveSec = "45m";
      };
    };
  };
}
