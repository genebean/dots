{
  config,
  lib,
  ...
}:
let
  cfg = config.genebean.programs.mcp-nixos;
in
{
  options.genebean.programs.mcp-nixos = {
    enable = lib.mkEnableOption "mcp-nixos MCP server for NixOS/Home Manager/nix-darwin";
  };

  config = lib.mkIf cfg.enable {
    # Our pinned nixpkgs (26.05) carries mcp-nixos 2.4.3, whose dependency
    # chain (-> fastmcp -> py-key-value-aio -> duckdb -> pyarrow ->
    # arrow-cpp -> thrift) fails to build on CI: thrift's bundled Catch2
    # test suite doesn't compile against mightymac's newer Apple SDK
    # libc++, and mcp-nixos's own test suite has an unrelated flaky
    # assertion against a randomly-picked /nix/store file. Sourcing it from
    # nixpkgs-unstable directly dodged that, but nixpkgs-unstable later
    # broke it a different way (python3.14-fastmcp-slim marked broken) when
    # it advanced to pick up an unrelated fix. Pinning the exact
    # known-good published version via nixpkgs-multiverse sidesteps both
    # channels' churn instead of chasing either one.
    multiverse.pins.mcp-nixos = "3.0.1";
    home.packages = [ config.multiverse.pinned.mcp-nixos ];
  };
}
