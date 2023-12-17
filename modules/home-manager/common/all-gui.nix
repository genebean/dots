{ pkgs, genebean-omp-themes, ... }: {
  home.packages = with pkgs; [
    element-desktop
  ];
  programs = {
    vscode = {
      enable = true;
    };
  };
}