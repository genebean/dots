# Republishes an upstream podcast RSS feed with only the episodes matching a
# text filter. Reads its configuration from the FEED_CONFIG/OUTPUT_DIR/
# PUBLIC_URL environment variables - see modules/genebean/nixos/services/
# filtered-podcast-feeds.nix for the NixOS service that wires those up.
{ writers }:
writers.writePython3Bin "filtered-podcast-feeds" {
  libraries =
    ps: with ps; [
      lxml
      requests
    ];
  # flake8's default 79-column limit is stricter than this repo's style
  # elsewhere; the logic reads fine at the lengths used here.
  flakeIgnore = [ "E501" ];
} (builtins.readFile ./generator.py)
