{ config, pkgs, hostname, username, ... }: {
  imports = [
    ./linux/internationalisation.nix
  ];

  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = with pkgs; [
      dconf2nix
      file
      neofetch
      python3
      tailscale
      unzip
      wget
    ];
  };

  fonts.fontDir.enable = false;
  fonts.packages = with pkgs; [
    font-awesome
    (nerdfonts.override {
      fonts = [
        "Hack"
        "SourceCodePro"
      ];
    })
  ];

  networking.hostName = "${hostname}";

  nix.settings = {
    allowed-users = [ "${username}" ];
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    trusted-users = [ "${username}" ];
  };

  programs = {
    zsh.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services.tailscale = {
    enable = true;
  };

  time.timeZone = "America/New_York";

  users.defaultUserShell = pkgs.zsh;
}
