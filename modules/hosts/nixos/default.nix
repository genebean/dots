{ hostname, pkgs, username, ... }: {
  imports = [
    ../common/linux/internationalisation.nix
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
      mosquitto
      neofetch
      python3
      smartmontools
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
    nerd-fonts.hack
    # Pulled from https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    nerd-fonts.sauce-code-pro
  ];

  networking.hostName = "${hostname}";

  nix.settings = {
    allowed-users = [ "${username}" ];
    download-buffer-size = 524288000;
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
