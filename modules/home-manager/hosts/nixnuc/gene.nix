{ ... }: {
  home.stateVersion = "23.11";
  imports = [
    ../../common/all-cli.nix
    ../../common/all-linux.nix
  ];  
}
