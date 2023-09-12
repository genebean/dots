{ pkgs, ... }: {
  system.stateVersion = 4;

  environment = {
    shells = with pkgs; [ bash zsh ];
    loginShell = pkgs.zsh;
    pathsToLink = [
      "/Applications"
      "/share/zsh"
    ];
    systemPackages = with pkgs; [
      coreutils
      chart-testing
      colordiff
      dog
      dos2unix
      du-dust
      element-desktop
      gotop
      hub
      hugo
      kopia
      kubectx
      mas
      mtr
      nmap
      nodejs
      nodePackages.npm
      openjdk
      rename
      tree
      watch
      wget
      yq
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
      "hashicorp/tap"
      # "homebrew/bundle"
      "homebrew/cask-fonts"
      # "jandedobbeleer/oh-my-posh"
      "null-dev/firefox-profile-switcher"
      "puppetlabs/puppet"
    ];
    brews = [
      "adr-tools"
      "helm"
      "kubernetes-cli"
    ];
    casks = [
      "1password"
      "amethyst"
      "audacity"
      "cakebrew"
      "elgato-stream-deck"
      "firefox"
      "font-hack-nerd-font"
      "font-inconsolata-g-for-powerline"
      "font-source-code-pro-for-powerline"
      "google-drive"
      "iterm2"
      "keepingyouawake"
      "kopiaui"
      "libreoffice"
      "logseq"
      "meld"
      "nextcloud"
      "obs"
      "onlyoffice"
      "pdk"
      "puppet-bolt"
      "qmk-toolbox"
      "raycast"
      "signal"
      "slack"
      "tailscale"
      "thunderbird"
      "vagrant"
      "virtualbox"
      "visual-studio-code"
      "vivaldi"
      "vlc"
      "whatsapp"
      "zenmap"
      "zoom"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "BetterSnapTool" = 417375580;
      "Home Assistant" = 1099568401;
      "HomeCam" = 1292995895;
      "MeetingBar" = 1532419400;
      "Microsoft Remote Desktop" = 1295203466;
    };
  };

  nix = {
    settings = {
      bash-prompt-prefix = "(nix:$name)\040";
      build-users-group = "nixbld";
      experimental-features = [
        "auto-allocate-uids"
        "flakes"
        "nix-command"
      ];
    };
    extraOptions = ''
      # Generated by https://github.com/DeterminateSystems/nix-installer, version 0.11.0.
      extra-nix-path = nixpkgs=flake:nixpkgs
    '';
  };

  programs.zsh.enable = true;

  services.nix-daemon.enable = true;

  users.users."gene.liverman" = {
    home = "/Users/gene.liverman";
    shell = pkgs.zsh;
  };
}
