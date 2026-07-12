{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.mqtt-explorer.enable {
    homebrew.masApps = {
      "MQTT Explorer" = 1455214828;
    };
  };
}
