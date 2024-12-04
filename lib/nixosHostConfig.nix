{ inputs, nixpkgs, nixpkgs-unstable, compose2nix, disko, flox, genebean-omp-themes,
    home-manager, nix-darwin, nix-flatpak, nix-homebrew, nixos-cosmic,
    nixos-hardware, nixpkgs-terraform, simple-nixos-mailserver, sops-nix, ...
}: {
  nixosHostConfig = { system ? "x86_64-linux", hostname, username ? "gene", additionalModules ? [], additionalSpecialArgs ? {} }: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs compose2nix hostname username; } // additionalSpecialArgs;
    modules = [
      # move this to a common file later
      ({
        nixpkgs = {
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "olm-3.2.16" "electron-27.3.11" ];
          };
          overlays = [ nixpkgs-terraform.overlays.default ];
        };
      })

      disko.nixosModules.disko

      home-manager.nixosModules.home-manager {
        home-manager = {
          extraSpecialArgs = { inherit genebean-omp-themes hostname username; };
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username}.imports = [
            ../modules/home-manager/hosts/${hostname}/${username}.nix
          ];
        };
      }

      nix-flatpak.nixosModules.nix-flatpak

      sops-nix.nixosModules.sops # system wide secrets management
      ../modules/system/common/all-nixos.nix # system-wide stuff
      ../modules/hosts/nixos/${hostname} # host specific stuff
    ] ++ additionalModules;
  };
}