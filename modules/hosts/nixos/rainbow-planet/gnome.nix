{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome.nautilus
    gnomeExtensions.dash-to-panel
    gnome.networkmanager-openvpn
    gnomeExtensions.pop-shell
    gnomeExtensions.tailscale-qs
    pop-gtk-theme
    pop-icon-theme
    pop-launcher
  ];

  services = {
    gnome.gnome-keyring.enable = true; # Provides secret storage
    gvfs.enable = true; # Used by Nautilus
    xserver = {
      enable = true;    # Enable the X11 windowing system.

      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };

      # displayManager = {
      #   gdm = {
      #     enable = true;
      #     wayland = true;
      #   };
      # };
      desktopManager.gnome.enable = true;
    };
  };
}

