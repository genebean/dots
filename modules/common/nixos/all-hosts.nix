{ config, pkgs, ... }: {
  imports = [
    ./internationalisation.nix
  ];

  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = with pkgs; [
      angryipscanner
      dconf2nix
      file
      neofetch
      python3
      tailscale
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

  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
    ];
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