{ pkgs, ... }: {
  system.stateVersion = 4;

  environment = {
    systemPackages = with pkgs; [
      chart-testing
      kopia
      kubectx
    ];
  };

  homebrew = {
    taps = [
      "hashicorp/tap"
      # "homebrew/bundle"
      # "jandedobbeleer/oh-my-posh"
      "puppetlabs/puppet"
    ];
    brews = [
      "adr-tools"
      "helm"
      "kind"
      "kubernetes-cli"
      "lima"
      "podman"
    ];
    casks = [
      "asana"
      "boinc"
      "discord"
      "elgato-stream-deck"
      "google-drive"
      "kopiaui"
      "obs"
      "pdk"
      "podman-desktop"
      "puppet-agent"
      "puppet-bolt"
      "qmk-toolbox"
      "thunderbird"
      "utm"
      "vagrant"
      "vial"
      "waterfox"
      "whalebird"
      "zenmap"
    ];
    masApps = {
      "HomeCam" = 1292995895;
      "Keeper Password Manager" = 414781829;
      "MeetingBar" = 1532419400;
      "Microsoft Remote Desktop" = 1295203466;
      "Telegram" = 747648890;
      "WhatsApp Messenger" = 310633997;
    };
  };
}
