{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.thunderbird.enable {
    homebrew.casks = [ "thunderbird" ];
  };
}
