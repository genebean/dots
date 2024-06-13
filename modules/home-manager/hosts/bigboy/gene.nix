{ pkgs, ... }: {
  home.stateVersion = "24.05";
  imports = [
    ../../common/all-cli.nix
    ../../common/all-gui.nix
    ../../common/all-linux.nix
    ../../common/linux-apps/tilix.nix
    ../../common/linux-apps/xfce4-terminal.nix
  ];

  programs.vscode = {
    enable = true;
  };
}

