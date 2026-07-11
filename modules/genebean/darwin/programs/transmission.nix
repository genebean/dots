{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.transmission.enable {
    homebrew.casks = [ "transmission" ];
  };
}
