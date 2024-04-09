{ pkgs, flox-flake, hostname, username, ... }: {
  environment = {
    shells = with pkgs; [ bash zsh ];
    loginShell = pkgs.zsh;
    pathsToLink = [
      "/Applications"
      "/share/zsh"
    ];
    systemPackages = with pkgs; [
      age
      bandwhich
      coreutils
      flox-flake.packages.${pkgs.system}.default
      hugo
      mas
      nmap
      openjdk
      sops
      ssh-to-age
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
      "fastfetch"
      "ffmpeg"
      "firefox-profile-switcher-connector"
      "telnet"
    ];
    casks = [
      "1password"
      "1password-cli"
      "amethyst"
      "angry-ip-scanner"
      "audacity"
      "balenaetcher"
      "bartender"
      #"displaylink"
      "element"
      "firefox"
      "font-hack-nerd-font"
      "font-inconsolata-g-for-powerline"
      "font-source-code-pro-for-powerline"
      "gitkraken"
      "gitkraken-cli"
      "handbrake"
      "imageoptim"
      "iterm2"
      "keepingyouawake"
      "libreoffice"
      "logseq"
      "makemkv"
      "meld"
      "MKVToolNix"
      "nextcloud"
      "onlyoffice"
      "raycast"
      "signal"
      "slack"
      "sonos"
      "tailscale"
      "vivaldi"
      "zoom"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "BetterSnapTool" = 417375580;
      "Brother iPrint&Scan" = 1193539993;
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
        "repl-flake"
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
      trusted-users = [ "@admin" "${username}" ];
    };
    extraOptions = ''
      # Generated by https://github.com/DeterminateSystems/nix-installer, version 0.11.0.
      extra-nix-path = nixpkgs=flake:nixpkgs
      # Uncoment below after validation bug is fixed
      #upgrade-nix-store-path-url = https://install.determinate.systems/nix-upgrade/stable/universal
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
