{ pkgs, genebean-omp-themes, ... }: {
  home.stateVersion = "23.11";
  imports = [
    ../../common/all-cli.nix
    ../../common/all-gui.nix
    ../../common/all-darwin.nix
  ];

}
