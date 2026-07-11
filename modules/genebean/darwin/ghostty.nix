{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.ghostty.installViaHomebrew {
    homebrew.casks = [ "ghostty" ];
  };
}
