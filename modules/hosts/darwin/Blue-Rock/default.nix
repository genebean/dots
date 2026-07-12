{ pkgs, ... }:
{
  system.stateVersion = 4;

  environment = {
    systemPackages = with pkgs; [
      chart-testing
      kopia
      kubectx
      python2
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
      "kubernetes-cli"
    ];
    casks = [
      "asana"
      "elgato-stream-deck"
      "google-drive"
      "obs"
      "puppet-agent"
      "puppet-bolt"
      "qmk-toolbox"
      "vagrant"
      "vial"
      "virtualbox"
      "whalebird"
      "zenmap"
    ];
    masApps = {
      "HomeCam" = 1292995895;
      "Keeper Password Manager" = 414781829;
      "MeetingBar" = 1532419400;
      "Microsoft Remote Desktop" = 1295203466;
      "WhatsApp Messenger" = 310633997;
    };
  };
}
