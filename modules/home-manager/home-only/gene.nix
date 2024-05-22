{ pkgs, genebean-omp-themes, ... }: {
  home.stateVersion = "23.11";
  imports = [
    ../common/all-cli.nix
    ../common/all-linux.nix
    ../common/hm-sops.nix
  ];
}
