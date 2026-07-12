{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.boinc.enable {
    services.boinc.enable = true;
  };
}
