{
  config,
  pkgs,
  ...
}:
{
  home.stateVersion = "25.05";

  dconf.settings = {
    # This is so that SUPER + D, the default for showing the desktop
    # in GNOME, can instead be used by WezTerm
    "org/gnome/desktop/wm/keybindings" = {
      show-desktop = [ ];
    };
  };

  genebean = {
    plasma.enable = true;
    programs = {
      ghostty.enable = true;
    };
    services = {
      flatpak.enable = true;
    };
  };

  home.packages = with pkgs; [
    home-manager
  ];

  programs = {
    codex.enable = true;
  };

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "attic-netrc".sopsFile = ../../shared/secrets.yaml;
      local_private_env.path = "${config.home.homeDirectory}/.private-env";
    };
  };

  # Auth for the self-hosted Attic cache (genebean/dots#677) - the
  # substituter URL/key live in modules/genebean/data/nix-caches.nix like
  # every other cache (written into system-wide nix.conf by
  # modules/genebean/system-manager/nix-caches.nix). Home-manager's own
  # nix.settings here, since this host has no system-level sops at all.
  # nix.package is only for generating nix.conf's content below - actual
  # Nix on this host is Determinate Nix, managed outside home-manager
  # entirely.
  nix = {
    package = pkgs.nix;
    settings.netrc-file = config.sops.secrets."attic-netrc".path;
    # Preserves the existing manually-created ~/.config/nix/nix.conf's
    # !include line (nix-auth's own access-tokens.conf) now that
    # home-manager generates this file instead.
    extraOptions = "!include access-tokens.conf";
  };

  # home-manager has never managed ~/.config/nix/nix.conf before now (no
  # nix.settings was set on this host until the line above) - this file
  # takes over from the pre-existing manually-created one, which already
  # had the same !include line restored by extraOptions above.
  xdg.configFile."nix/nix.conf".force = true;

}
