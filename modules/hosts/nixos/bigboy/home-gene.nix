{ ... }:
{
  home.stateVersion = "24.05";
  imports = [
    ../../../shared/home/general/all-gui.nix
    ../../../shared/home/linux/apps/tilix.nix
    ../../../shared/home/linux/apps/xfce4-terminal.nix
  ];

  programs = {
    vscode = {
      enable = true;
    };
    wezterm = {
      enable = true;
      extraConfig = ''
        -- This will hold the configuration.
        local config = wezterm.config_builder()

        -- This is where you actually apply your config choices

        -- For example, changing the color scheme:
        config.color_scheme = 'AdventureTime'

        -- and finally, return the configuration to wezterm
        return config
      '';
    };
  };
}
