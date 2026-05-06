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

  home.packages = with pkgs; [
    age
    home-manager
    r10k
    sops
    ssh-to-age
  ];

  # home-manager switch --flake ~/repos/dots
  programs.zsh.shellAliases = {
    nixdiff = "cd ~/repos/dots && home-manager build --flake .#${username}-${system} && nvd diff ${config.home.homeDirectory}/.local/state/nix/profiles/home-manager result";
    nixup = "home-manager switch --flake ~/repos/dots#${username}-${system}";
    pbcopy = "wl-copy";
  };

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_private_env.path = "${config.home.homeDirectory}/.private-env";
    };
  };

  xdg.configFile."wezterm/wezterm.lua".source = ../../shared/files/wezterm/wezterm.lua;
}
