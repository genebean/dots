{
  config,
  lib,
  username,
  ...
}:
{
  config =
    lib.mkIf config.home-manager.users.${username}.genebean.programs.wezterm.installViaHomebrew
      {
        homebrew.casks = [ "wezterm" ];
      };
}
