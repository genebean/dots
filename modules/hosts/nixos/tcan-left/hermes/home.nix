# Hermes agent fleet on tcan-left (Home Manager side): one
# genebean.services.hermesAgents.<name> declaration per agent - the real
# consumer-facing option (modules/genebean/home/services/hermes-agents.nix),
# per this repo's "Home Manager is always the consumer declaration point"
# convention (modules/genebean/README.md). The NixOS companion
# (modules/genebean/nixos/services/hermes-agents.nix) reads these back and
# does the actual system-level work: container, secrets, Forgejo/GitHub
# credential plumbing, skill materialization.
#
# The fleet is modeled on The West Wing's senior staff - each agent's own
# SOUL.md states its full character mapping; this is just a one-line
# pointer per agent, not a restatement:
#   - leo:     chief of staff (Leo McGarry) - coordinates the others
#   - charlie: Forgejo/planning aide (Charlie Young)
#   - danny:   independent social-reporting agent (Danny Concannon)
#   - cj:      press secretary (C.J. Cregg)
#   - sam:     GitHub/product-repo engineer (Sam Seaborn)
# "Jed" - the in-fleet "President" each agent's AGENTS.md answers to as the
# fleet's one real-human owner - is Gene, under his own Buzz account.
#
# There is no NixOS-side file anywhere in this subtree, including for
# Danny despite his digest-pipeline/MCP needs - every agent-specific thing
# goes through a genebean.services.hermesAgents option (mcpServers,
# extraContainerModules, secrets.<name>.envFileAs, etc.), never a
# hand-written containers.<name>.config.* override in a per-host file. See
# modules/genebean/nixos/services/hermes-agents.nix's own header for what
# that option surface currently covers.
#
# Adding a sixth agent needs a line added to BOTH the imports list below
# AND `knownAgentNames` in modules/genebean/nixos/services/hermes-agents.nix
# - that file's own comment explains why the second list can't just be
# derived from this one. Missing the second edit fails silently: the
# container simply never gets built, no error.
#
# Planning/issue tracking for this fleet ("hermes-agent-fleet-plan issue N",
# cited throughout this subtree) lives outside this repo, in the
# hermes-agent-fleet-plan Forgejo repo
# (git.home.technicalissues.us/genebean/hermes-agent-fleet-plan).
{
  imports = [
    ./leo/home.nix
    ./charlie/home.nix
    ./danny/home.nix
    ./cj/home.nix
    ./sam/home.nix
  ];
}
