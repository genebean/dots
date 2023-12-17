{ pkgs, hostname, username, ... }: {
  environment = {
    shells = with pkgs; [ bash zsh ];
    loginShell = pkgs.zsh;
    pathsToLink = [
      "/Applications"
      "/share/zsh"
    ];
    systemPackages = with pkgs; [
      coreutils
      hugo
      mas
      nmap
      nodejs
      nodePackages.npm
      openjdk
    ];
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    taps = [
      "homebrew/cask-fonts"
      "null-dev/firefox-profile-switcher"
    ];
    brews = [
      "ffmpeg"
      "firefox-profile-switcher-connector"
    ];
    casks = [
      "1password"
      "1password-cli"
      "amethyst"
      "angry-ip-scanner"
      "audacity"
      "balenaetcher"
      "firefox"
      "font-hack-nerd-font"
      "font-inconsolata-g-for-powerline"
      "font-source-code-pro-for-powerline"
      "iterm2"
      "keepingyouawake"
      "libreoffice"
      "logseq"
      "meld"
      "nextcloud"
      "onlyoffice"
      "raycast"
      "signal"
      "slack"
      "tailscale"
      "vivaldi"
      "vlc"
      "zoom"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "BetterSnapTool" = 417375580;
      "Home Assistant" = 1099568401;
      "MQTT Explorer" = 1455214828;
    };
  };

  networking.hostName = "${hostname}";

  nix = {
    settings = {
      bash-prompt-prefix = "(nix:$name)\040";
      build-users-group = "nixbld";
      experimental-features = [
        "auto-allocate-uids"
        "flakes"
        "nix-command"
      ];
      trusted-users = [ "@admin" "${username}" ];
    };
    extraOptions = ''
      # Generated by https://github.com/DeterminateSystems/nix-installer, version 0.11.0.
      extra-nix-path = nixpkgs=flake:nixpkgs
    '';
  };

  programs = {
    zsh.enable = true;
  };

  services.nix-daemon.enable = true;

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };
}
