{ pkgs, ... }: {
  home.stateVersion = "23.11";
  imports = [
    ../../common/all-cli.nix
    ../../common/all-gui.nix
    ../../common/all-linux.nix
  ];

  programs.vscode = {
    enable = true;
  };
}

