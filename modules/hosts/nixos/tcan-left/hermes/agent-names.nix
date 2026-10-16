# Hermes agent fleet on tcan-left: a plain list of agent names discovered
# automatically by mkNixosHost. The builder derives each
# hermes/<name>/home.nix path, imports it into Home Manager, and passes the
# same names to the NixOS companion as a recursion-safe index.
#
# Each module declares genebean.services.hermesAgents.<name> through the
# real consumer-facing Home Manager option, per this repo's "Home Manager
# is always the consumer declaration point" convention
# (modules/genebean/README.md). The NixOS companion reads those declarations
# back and does the actual system-level work: container, secrets,
# Forgejo/GitHub credential plumbing, and skill materialization.
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
# This list is the roster and import source of truth. Keeping it as plain
# data avoids asking either module system to enumerate the recursive Home
# Manager configuration. Adding an agent requires only its name here and a
# matching <name>/home.nix module.
#
# Planning/issue tracking for this fleet ("hermes-agent-fleet-plan issue N",
# cited throughout this subtree) lives outside this repo, in the
# hermes-agent-fleet-plan Forgejo repo
# (git.home.technicalissues.us/genebean/hermes-agent-fleet-plan).
[
  "leo"
  "charlie"
  "danny"
  "cj"
  "sam"
]
