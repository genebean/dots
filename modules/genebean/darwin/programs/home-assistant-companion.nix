{
  config,
  lib,
  username,
  ...
}:
{
  config =
    lib.mkIf config.home-manager.users.${username}.genebean.programs.home-assistant-companion.enable
      {
        homebrew.masApps = {
          "Home Assistant" = 1099568401;
        };
      };
}
