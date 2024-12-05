{ ... }: {
  home.stateVersion = "24.05";
  imports = [
    ../../common/all-cli.nix
    ../../common/all-linux.nix
  ];  
}
