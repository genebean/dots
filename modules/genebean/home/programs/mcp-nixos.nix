{
  config,
  lib,
  pkgs,
  inputs,
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
    # assertion against a randomly-picked /nix/store file. nixpkgs-unstable
    # already carries a newer release built against a newer fastmcp that
    # doesn't pull in that chain - source it from there instead of
    # papering over either failure with per-package overrides.
    home.packages = [
      (import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; }).mcp-nixos
    ];
  };
}
