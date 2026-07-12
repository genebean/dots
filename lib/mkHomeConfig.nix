{ inputs, ... }:
let
  inherit (import ./default.nix { inherit inputs; }) genebeanLib;
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
          genebeanLib
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

        {
          home = {
            username = "${username}";
            homeDirectory = "${homeDirectory}";
          };
        }

        inputs.genebean-neovim.homeManagerModules.default
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.private-flake.homeManagerModules.private.git
        inputs.self.homeManagerModules.genebean
        inputs.sops-nix.homeManagerModules.sops
      ];
    };
}
