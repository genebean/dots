# Sam: the GitHub product-repo worker (mylittletechbot). Forks, branches,
# commits, and opens PRs against dots and the Hermes app repos - never
# self-merges, see AGENTS.md. No private-flake access (it moved to
# Forgejo; Sam holds no Forgejo credential). Any relay member can
# technically message it (BUZZ_ALLOW_ALL_USERS, the shared
# hermes-agents.nix default); the "only act on Leo's instructions" rule
# is judgment enforced in AGENTS.md, not a technical allow-list - same
# shape as Charlie.
#
# GitHub App, not a PAT (hermes-agent-fleet-plan's authority-boundaries.md
# explicitly prefers this): a GitHub App's private key mints short-lived
# (1 hour) installation access tokens on demand, instead of a long-lived
# static secret sitting on the host regardless of scoping.
#
# Two separate Apps - "sam-mylittletechbot" (app id 5204628, the public
# product-repo fork/PR workflow, installed on mylittletechbot - all repos
# it owns) and a second, separate App (app id 5288757, scoped only to
# genebean/agent-ideas, installed directly on genebean since that's the
# only way to reach a repo mylittletechbot is merely a collaborator on).
# Deliberately kept fully separate: different id, different key, different
# token, different wrapper command - confirmed live (2026-10-12) each
# attributes as its own distinct bot identity, and neither App can reach
# the other's scope.
#
# This Home Manager module is registered in ../agent-names.nix and imported by
# tcan-left's mkNixosHost call - see leo/home.nix's header for why.
{ pkgs, buzzChannels, ... }:
{
  genebean.services.hermesAgents.sam = {
    stateVersion = "26.05";

    agentsFile = ./AGENTS.md;

    extraPackages = [
      pkgs.gh
      pkgs.gh-token
      pkgs.jq
    ];

    githubApps = {
      agentIdeas = {
        appId = "5288757";
        keySecretName = "hermes_sam_agent_ideas_app_key";
        wrapperName = "sam-gh-ideas";
      };
      product = {
        appId = "5204628";
        gitCredentialHelper = true;
        keySecretName = "hermes_sam_github_app_key";
        wrapperName = "sam-gh";
      };
    };

    hermesSettings = {
      model = {
        default = "gpt-5.6-sol"; # matches the rest of the fleet
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
        # hermes-agents.nix) - Sam only activates on an explicit
        # @-mention or a reply to its own message, same as Charlie.
      };
    };

    # Staggered 1hr apart from the rest of the fleet's own reconciliation
    # sessions (Thursdays, Danny last at the default 17:00) so they don't
    # all race each other - see hermes-agents.nix's own option doc.
    reconciliationSchedule = "0 16 * * 4";

    secrets = {
      hermes_sam_agent_ideas_app_key = { };
      hermes_sam_buzz_identity.toEnvironmentFile = true;
      hermes_sam_github_app_key = { };
    };

    sharedSkills = [ "newspaper-access" ];

    soulFile = ./SOUL.md;
  };
}
