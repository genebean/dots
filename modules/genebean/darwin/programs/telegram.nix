{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.telegram.enable {
    homebrew.masApps = {
      "Telegram" = 747648890;
    };
  };
}
