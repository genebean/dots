{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.claude-code.enable {
    homebrew.casks = [ "claude-code" ];
  };
}
