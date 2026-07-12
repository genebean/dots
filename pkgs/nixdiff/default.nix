{ pkgs }:
pkgs.writeShellApplication {
  name = "nixdiff";
  runtimeInputs = [
    pkgs.jq
    pkgs.nvd
  ];
  text = if pkgs.stdenv.isDarwin then builtins.readFile ./darwin.sh else builtins.readFile ./linux.sh;
}
