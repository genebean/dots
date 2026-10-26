{ inputs, ... }:
let
  inherit (import ./default.nix { inherit inputs; }) genebeanLib;
  buzzChannels = import ../modules/genebean/data/buzz-channels.nix;
in
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
          buzzChannels
          ;
        genebeanLib = genebeanLib // {
          isHMOnly = true;
        };
      };

      pkgs = inputs.nixpkgs.legacyPackages.${system};

      # Specify your home configuration modules here, for example,
      # the path to your home.nix.
      modules = [
        ./nixpkgs-settings.nix
        ../modules/hosts/home-manager-only
        ../modules/hosts/home-manager-only/home-${username}.nix
        ../modules/shared/home/general
        ../modules/shared/home/general/all-gui.nix

        {
          home = {
            username = "${username}";
            homeDirectory = "${homeDirectory}";
          };
        }

        inputs.genebean-neovim.homeManagerModules.default
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.nixpkgs-multiverse.homeManagerModules.default
        { multiverse.enable = true; } # package-version pinning - see flake.nix's nixpkgs-multiverse input
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.private-flake.homeManagerModules.private.git
        inputs.self.homeManagerModules.genebean
        inputs.sops-nix.homeManagerModules.sops
      ];
    };
}
