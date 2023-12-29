{ pkgs, genebean-omp-themes, ... }: {
  home.packages = with pkgs; [
    # nothing here right now
  ];
  programs = {
    vscode = {
      enable = true;
    };
  };
}
