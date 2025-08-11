{ pkgs, ... }: {
  # Settings just for personal machines go here

  home.packages = with pkgs; [
    chirp
  ];
}
