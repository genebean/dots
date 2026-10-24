{ inputs, ... }:
let
  inherit (import ./default.nix { inherit inputs; }) genebeanLib;
  buzzChannels = import ../modules/genebean/data/buzz-channels.nix;
in
{
  mkNixosHost =
    {
      system ? "x86_64-linux",
      hostname,
      username ? "gene",
      additionalHomeModules ? [ ],
      additionalModules ? [ ],
      additionalSpecialArgs ? { },
    }:
    let
      # The Hermes NixOS companion needs an agent-name index that is
      # available before the NixOS/Home Manager fixed point is evaluated.
      # Checking an optional path inside the fixed flake source is pure;
      # hosts without a roster simply get no agent modules.
      hermesAgentNamesPath = ../modules/hosts/nixos/${hostname}/hermes/agent-names.nix;
      hermesAgentNames =
        if builtins.pathExists hermesAgentNamesPath then import hermesAgentNamesPath else [ ];
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          hostname
          username
          hermesAgentNames
          ;
      }
      // additionalSpecialArgs;
      modules = [
        ./nixpkgs-settings.nix

        inputs.disko.nixosModules.disko

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit
                inputs
                hostname
                username
                buzzChannels
                ;
              genebeanLib = genebeanLib // {
                isNixOS = true;
              };
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ../modules/shared/home/general
              ../modules/hosts/nixos/${hostname}/home-${username}.nix

              inputs.genebean-neovim.homeManagerModules.default
              inputs.nix-flatpak.homeManagerModules.nix-flatpak
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.private-flake.homeManagerModules.private.git
              (inputs.private-flake.homeManagerModules.private.${hostname} or { })
              inputs.self.homeManagerModules.genebean
            ]
            # Each roster entry follows the host-local
            # hermes/<name>/home.nix convention. These remain Home Manager
            # consumer declarations; only their names cross into NixOS.
            ++ map (agentName: ../modules/hosts/nixos/${hostname}/hermes/${agentName}/home.nix) hermesAgentNames
            ++ additionalHomeModules;
          };
        }

        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.nixpkgs-multiverse.nixosModules.default
        { multiverse.enable = true; } # package-version pinning - see flake.nix's nixpkgs-multiverse input
        inputs.private-flake.nixosModules.private.ssh-keys
        inputs.self.nixosModules.genebean
        inputs.sops-nix.nixosModules.sops # system wide secrets management
        ../modules/hosts/nixos # system-wide stuff
        ../modules/hosts/nixos/${hostname} # host specific stuff
      ]
      ++ additionalModules;
    };
}
