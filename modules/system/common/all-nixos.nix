{ config, hostname, pkgs, sops-nix, username, ... }: {
  imports = [
    ./linux/internationalisation.nix
  ];

  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = with pkgs; [
      age
      dconf2nix
      file
      inetutils
      iotop
      neofetch
      python3
      sops
      ssh-to-age
      sysstat
      tailscale
      unzip
      wget
      xidel
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
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-substituters = [
      "https://cache.flox.dev"
    ];
    trusted-users = [ "${username}" ];
  };

  programs = {
    bandwhich.enable = true;
    zsh.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh.enable = true;
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  time.timeZone = "America/New_York";

  users.defaultUserShell = pkgs.zsh;
}
