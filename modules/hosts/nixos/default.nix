{
  hostname,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../shared/nixos/internationalisation.nix
  ];

  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    systemPackages = with pkgs; [
      age
      claude-code
      dconf2nix
      file
      iftop
      inetutils
      iotop
      lsof
      mosquitto
      net-tools
      python3
      rclone
      smartmontools
      sops
      ssh-to-age
      sysstat
      tailscale
      unzip
      wget
      xidel
    ];
  };

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.hack
    # Pulled from https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    nerd-fonts.sauce-code-pro
  ];

  networking.hostName = "${hostname}";

  nix.settings = {
    allowed-users = [ "${username}" ];
    download-buffer-size = 524288000;
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    extra-substituters = [
      "https://cache.flox.dev"
      "https://cache.numtide.com"
      "https://cache.thalheim.io"
      "https://cosmic.cachix.org/"
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
    trusted-users = [ "${username}" ];
  };

  programs = {
    bandwhich.enable = true;
    zsh.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh.enable = true;
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # dbus-broker's unit is Type=notify-reload, but it doesn't send the
  # RELOADING=1/READY=1 handshake systemd expects for that type - every
  # `nixos-rebuild switch`/deploy that touches its config hangs for the
  # full TimeoutStartSec (90s) then fails the whole activation. This is
  # an upstream systemd/dbus-broker bug (systemd/systemd#37515), not
  # anything host-specific - confirmed reproduced on nixnuc, but every
  # host is equally exposed once something changes dbus-broker's
  # config.
  #
  # Restarting instead of reloading isn't safe either - also confirmed
  # on nixnuc: switch-to-configuration's own remaining steps (starting
  # other changed units) talk to systemd over D-Bus, so stopping
  # dbus-broker mid-switch stranded the activation script with "Failed
  # to process dbus messages... disconnected from D-Bus?" and left the
  # bus down until a manual `systemctl start dbus.socket` - a real
  # outage on a host running "most services" (see AGENTS.md). Since
  # this is such a foundational service, the safe answer is to leave it
  # untouched by every switch entirely (neither reload nor restart) and
  # let it only actually pick up a new dbus-broker on the next real
  # reboot, same as how systemd itself is typically treated.
  systemd.services.dbus-broker = {
    reloadIfChanged = lib.mkForce false;
    restartIfChanged = lib.mkForce false;
  };

  time.timeZone = "America/New_York";

  users.defaultUserShell = pkgs.zsh;
}
