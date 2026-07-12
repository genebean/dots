{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.libreoffice.enable {
    homebrew.casks = [ "libreoffice" ];
  };
}
