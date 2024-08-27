{ inputs, pkgs, ... }: {
  system.stateVersion = 4;

  environment = {
    systemPackages = with pkgs; [
      chart-testing
      goreleaser
      inputs.flox.packages.${pkgs.system}.default
      kopia
      kubectx
      reposurgeon
      step-cli
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
      "wouterdebie/repo"
    ];
    brews = [
      "adr-tools"
      "argocd"
      "awscli"
      "cilium-cli"
      "helm"
      "hubble"
      "i2cssh"
      "kind"
      "kubernetes-cli"
      "kubeseal"
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
      "mumble"
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
