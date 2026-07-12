{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.mumble.enable {
    homebrew.casks = [ "mumble" ];
  };
}
