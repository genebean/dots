{ pkgs, ... }: {
  system.stateVersion = 4;

  environment = {
    systemPackages = with pkgs; [
      chart-testing
      goreleaser
      kopia
      kubectx
      reposurgeon
      # terraform-versions."1.5.7"
      terraformer
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
      "awscli"
      "helm"
      "kind"
      "kubernetes-cli"
      "lima"
      "opentofu"
      "node_exporter"
      "podman"
      "telegraf"
      "terraform-docs"
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
