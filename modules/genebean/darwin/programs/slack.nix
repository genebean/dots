{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.slack.enable {
    homebrew.casks = [ "slack" ];
  };
}
