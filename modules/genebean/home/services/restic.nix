{ lib, ... }:
{
  options.genebean.services.restic = {
    enable = lib.mkEnableOption "shared restic backup infrastructure (backup + cheap per-host forget)";

    enablePruneJob = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run the expensive, fleet-wide restic prune (data reclaim) job on this host. Must be true on EXACTLY ONE host across the whole fleet - prune is a whole-repository operation (it has to know what data every host's remaining snapshots still reference), so running it on more than one host wastes redundant work and running it on zero means space is never reclaimed. Enforced by a pre-commit check (scripts/check-restic-prune-singleton.sh).";
    };
  };
}
