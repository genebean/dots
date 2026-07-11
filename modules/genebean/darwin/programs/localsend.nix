{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.localsend.enable {
    homebrew.masApps = {
      "LocalSend" = 1661733229;
    };
  };
}
