{ pkgs, ... }: let
  user = "gene.liverman";
in {
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
      hugo
      kopia
      kubectx
      mas
      nmap
      nodejs
      nodePackages.npm
      openjdk
      python2
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
      "firefox-profile-switcher-connector"
      "helm"
      "kubernetes-cli"
    ];
    casks = [
      "1password"
      "1password-cli"
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
      "puppet-agent"
      "puppet-bolt"
      "qmk-toolbox"
      "raycast"
      "signal"
      "slack"
      "tailscale"
      "thunderbird"
      # "tunnelblick"
      "vagrant"
      "vivaldi"
      "virtualbox"
      "vlc"
      "whalebird"
      "whatsapp"
      "zenmap"
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
      trusted-users = [ "@admin" "${user}" ];
    };
    extraOptions = ''
      # Generated by https://github.com/DeterminateSystems/nix-installer, version 0.11.0.
      extra-nix-path = nixpkgs=flake:nixpkgs
    '';
  };

  programs.zsh.enable = true;

  services.nix-daemon.enable = true;

  users.users.${user} = {
    home = "/Users/${user}";
    shell = pkgs.zsh;
  };
}
