{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.logseq.enable {
    homebrew.casks = [ "logseq" ];
  };
}
