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
      iftop
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

  fonts.fontDir.enable = true;
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
    # extra-substituters = [
    # ];
    # extra-trusted-public-keys = [
    # ];
    substituters = [
      "https://cache.nixos.org" # default one
      "https://cache.flox.dev"
      "https://cosmic.cachix.org/"
      "https://nixpkgs-terraform.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" # default one
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "nixpkgs-terraform.cachix.org-1:8Sit092rIdAVENA3ZVeH9hzSiqI/jng6JiCrQ1Dmusw="
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
