{ inputs, ... }: {
  nixosHostConfig = {
    system ? "x86_64-linux",
    hostname,
    username ? "gene",
    additionalModules ? [],
    additionalSpecialArgs ? {}
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs hostname username; } // additionalSpecialArgs;
    modules = [
      # move this to a common file later
      ({
        nixpkgs = {
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "olm-3.2.16" "electron-27.3.11" ];
          };
          overlays = [ inputs.nixpkgs-terraform.overlays.default ];
        };
      })

      inputs.disko.nixosModules.disko

      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          extraSpecialArgs = { inherit inputs hostname username; };
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username}.imports = [
            ../modules/home-manager/hosts/${hostname}/${username}.nix
          ];
        };
      }

      inputs.nix-flatpak.nixosModules.nix-flatpak

      inputs.sops-nix.nixosModules.sops # system wide secrets management
      ../modules/system/common/all-nixos.nix # system-wide stuff
      ../modules/hosts/nixos/${hostname} # host specific stuff
    ] ++ additionalModules;
  };
}