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
      neofetch
      python3
      sops
      ssh-to-age
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
    trusted-users = [ "${username}" ];
  };

  programs = {
    zsh.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh.enable = true;
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_key.path;
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
        sopsFile = ../../hosts/nixos/${hostname}/secrets.yaml;
      };
    };
  };

  time.timeZone = "America/New_York";

  users.defaultUserShell = pkgs.zsh;
}
