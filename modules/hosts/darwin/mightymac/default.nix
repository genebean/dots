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
      "kompose"
      "kubernetes-cli"
      "kubeseal"
      "lima"
      "linkerd"
      "minio-mc"
      "opentofu"
      "node_exporter"
      "podman"
      "qemu"
      "telegraf"
      "terraform-docs"
    ];
    casks = [
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
      "whalebird"
      "zenmap"
    ];
    masApps = {
      "HomeCam" = 1292995895;
      "Keeper Password Manager" = 414781829;
      "MeetingBar" = 1532419400;
      "Messenger" = 1480068668;
      "Microsoft Remote Desktop" = 1295203466;
      "Telegram" = 747648890;
      "WhatsApp Messenger" = 310633997;
      "Xcode" = 497799835;
    };
  };
}
