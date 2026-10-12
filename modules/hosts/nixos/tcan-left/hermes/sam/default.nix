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

  # Second, separate App - "sam-mylittletechbot" (app id 5288757), installed
  # directly on genebean, scoped to only genebean/agent-ideas (Issues:
  # read+write, Contents: read). Confirmed live (2026-10-12) that an
  # installation token from this App attributes as its own bot identity
  # (sam-mylittletechbot[bot]), never as genebean - verified before wiring
  # this in, not assumed. Kept fully separate from the product-repo App
  # above: different id, different key, different token file, different
  # wrapper - this one can never be reached for anything broader than
  # agent-ideas, and the product-repo App can never reach agent-ideas at all
  # (mylittletechbot only sees repos it owns, confirmed the hard way -
  # "No repositories found" when trying to select agent-ideas from an
  # install on mylittletechbot).
  githubAppAgentIdeasId = "5288757";
  githubAppAgentIdeasKeyPath = "/run/secrets/hermes_sam_agent_ideas_app_key";

  agentIdeasTokenFile = "/run/sam-agent-ideas-token";

  samGhIdeas = pkgs.writeShellScriptBin "sam-gh-ideas" ''
    set -euo pipefail
    token=$(cat ${agentIdeasTokenFile})
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

      secretBindMounts = {
        "${githubAppKeyPath}" = {
          hostPath = config.sops.secrets.hermes_sam_github_app_key.path;
          isReadOnly = true;
        };
        "${githubAppAgentIdeasKeyPath}" = {
          hostPath = config.sops.secrets.hermes_sam_agent_ideas_app_key.path;
          isReadOnly = true;
        };
        "/run/secrets/hermes_sam_buzz_identity" = {
          hostPath = config.sops.secrets.hermes_sam_buzz_identity.path;
          isReadOnly = true;
        };
      };
      environmentFiles = [ "/run/secrets/hermes_sam_buzz_identity" ];

      extraPackages = [
        pkgs.gh
        pkgs.gh-token
        pkgs.git
        pkgs.jq
        samGh
        samGhIdeas
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

        # Self-reschedule rather than relying solely on the OnCalendar timer
        # below re-arming on its own - confirmed live (2026-10-12) that it
        # can get stuck after a container reboot: it fires once via its
        # Persistent catch-up, then silently never computes a next elapse
        # again (next_elapse frozen at the same timestamp as the last
        # trigger, NextElapseUSecRealtime empty, `list-timers` shows
        # Trigger: n/a) - for days, until manually restarted. A fresh
        # transient timer each run has no prior state to get stuck on.
        # `|| true` so a rare naming collision with an already-pending
        # reschedule doesn't fail this run after the token mint already
        # succeeded; the OnCalendar timer below remains as a backstop.
        ${pkgs.systemd}/bin/systemd-run --on-active=2700 --collect \
          --unit=sam-github-token-refresh-reschedule \
          --description="Reschedule Sam's GitHub token refresh" \
          ${pkgs.systemd}/bin/systemctl start sam-github-token-refresh.service || true
      '';
    };

    # Installation tokens expire after 1 hour - refresh well ahead of that.
    # OnUnitActiveSec doesn't work here - confirmed live (2026-10-07, token
    # went stale ~5 hours after the one and only refresh). It fires relative
    # to the target unit's last active-state *transition*, but this service
    # is Type=oneshot + RemainAfterExit=true, so it transitions into
    # "active" exactly once and then stays there forever - there's never a
    # second transition for OnUnitActiveSec to re-anchor against, so it
    # only ever fires once, ever. OnCalendar is wall-clock based and has no
    # such dependency on the target unit's own state - but it has its own
    # failure mode (see the self-reschedule above), so it's now a backstop
    # rather than the sole mechanism.
    timers.sam-github-token-refresh = {
      description = "Refresh Sam's GitHub App installation token before it expires";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/45"; # every 45 minutes, on the hour and :45
        Persistent = true; # catch up immediately if the container was down
      };
    };

    # Second App's refresh, same shape as sam-github-token-refresh above -
    # see that service's comments for why root-only/derived-token-only and
    # why the self-reschedule exists. Built with the self-reschedule from
    # the start here, not added after hitting the stuck-timer bug again.
    services.sam-agent-ideas-token-refresh = {
      description = "Mint Sam's genebean-installed GitHub App installation token (agent-ideas)";
      wantedBy = [ "multi-user.target" ];
      before = [ "hermes-agent.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        installation_id=$(${pkgs.gh-token}/bin/gh-token installations \
          --key ${githubAppAgentIdeasKeyPath} --app-id ${githubAppAgentIdeasId} | ${pkgs.jq}/bin/jq -r '.[0].id')
        token=$(${pkgs.gh-token}/bin/gh-token generate \
          --key ${githubAppAgentIdeasKeyPath} --app-id ${githubAppAgentIdeasId} \
          --installation-id "$installation_id" | ${pkgs.jq}/bin/jq -r '.token')
        tmpfile=$(${pkgs.coreutils}/bin/mktemp ${agentIdeasTokenFile}.XXXXXX)
        printf '%s' "$token" > "$tmpfile"
        ${pkgs.coreutils}/bin/chown hermes:hermes "$tmpfile"
        ${pkgs.coreutils}/bin/chmod 0440 "$tmpfile"
        ${pkgs.coreutils}/bin/mv -f "$tmpfile" ${agentIdeasTokenFile}

        ${pkgs.systemd}/bin/systemd-run --on-active=2700 --collect \
          --unit=sam-agent-ideas-token-refresh-reschedule \
          --description="Reschedule Sam's agent-ideas GitHub token refresh" \
          ${pkgs.systemd}/bin/systemctl start sam-agent-ideas-token-refresh.service || true
      '';
    };

    timers.sam-agent-ideas-token-refresh = {
      description = "Refresh Sam's genebean-installed GitHub App installation token (backstop)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/45";
        Persistent = true;
      };
    };
  };
}
