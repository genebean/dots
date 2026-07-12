# genebean.services.flatpak works in both NixOS and Home Manager contexts:
# the NixOS side (here) enables the system service; the HM side manages
# per-user packages and auto-update settings.
{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.flatpak;
in
{
  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
