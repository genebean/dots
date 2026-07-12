{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.xfce4-terminal.enable {
    programs.xfconf.enable = true;
  };
}
