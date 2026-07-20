{ lib, username, ... }:
{
  options.genebean.services.kiosk-backups = {
    enable = lib.mkEnableOption "restic-based disaster-recovery backups for kiosk state (chromium profile, atuin session, tailscale identity)";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/home/${username}/.config/chromium"
        "/home/${username}/.local/share/atuin"
        "/var/lib/tailscale"
      ];
      description = "Paths to back up daily and make available to kiosk-restic-full-restore. Must NOT include a /persist prefix - the NixOS side (modules/genebean/nixos/services/kiosk-backups.nix) adds that automatically when the host uses impermanence (environment.persistence.\"/persist\".enable). A path already starting with /persist is a configuration error - see that module's assertions.";
    };
  };
}
