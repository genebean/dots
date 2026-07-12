{
  config,
  pkgs,
  system,
  username,
  ...
}:
{
  home.stateVersion = "25.05";

  dconf.settings = {
    # This is so that SUPER + D, the default for showing the desktop
    # in GNOME, can instead be used by WezTerm
    "org/gnome/desktop/wm/keybindings" = {
      show-desktop = [ ];
    };
  };

  genebean = {
    plasma.enable = true;
    programs = {
      ghostty.enable = true;
    };
    services = {
      flatpak.enable = true;
    };
  };

  home.packages = with pkgs; [
    home-manager
  ];

  programs = {
    codex.enable = true;

    # home-manager switch --flake ~/repos/dots
    zsh.shellAliases = {
      nixup = "home-manager switch --flake ~/repos/dots#${username}-${system}";
      pbcopy = "wl-copy";
    };
  };

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_private_env.path = "${config.home.homeDirectory}/.private-env";
    };
  };

}
