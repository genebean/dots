{ inputs, ... }:
{
  mkHomeConfig =
    {
      homeDirectory,
      system,
      username,
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = {
        inherit
          inputs
          homeDirectory
          system
          username
          ;
      };

      pkgs = inputs.nixpkgs.legacyPackages.${system};

      # Specify your home configuration modules here, for example,
      # the path to your home.nix.
      modules = [
        ./nixpkgs-settings.nix
        ../modules/hosts/home-manager-only
        ../modules/hosts/home-manager-only/home-${username}.nix
        ../modules/shared/home/general
        ../modules/shared/linux/flatpaks.nix

        {
          home = {
            username = "${username}";
            homeDirectory = "${homeDirectory}";
          };
        }

        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.private-flake.homeManagerModules.private.git
        inputs.sops-nix.homeManagerModules.sops
      ];
    };
}
