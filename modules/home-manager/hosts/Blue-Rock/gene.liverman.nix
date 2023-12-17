{ pkgs, genebean-omp-themes, ... }: {
  home.stateVersion = "23.11";
  imports = [
    ../../common/all-cli.nix
    ../../common/all-gui.nix
    ../../common/all-darwin.nix
  ];
    
  programs = {
    go = {
      enable = true;
      goPath = "go";
    };
    k9s.enable = true;
  };

}
