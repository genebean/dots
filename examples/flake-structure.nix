{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    nix-darwin.url = "github:lnl7/nix-darwin";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = inputs@{ self, ... }: let
    # Import helper functions from lib/
    localLib = import ./lib { inherit inputs; };
  in {
    # Darwin (macOS) hosts
    darwinConfigurations = {
      mightymac = localLib.mkDarwinHost {
        system = "aarch64-darwin";
        hostname = "mightymac";
        username = "gene.liverman";
      };
    };

    # NixOS hosts
    nixosConfigurations = {
      rainbow-planet = localLib.mkNixosHost {
        system = "x86_64-linux";
        hostname = "rainbow-planet";
        username = "gene";
        additionalModules = [
          inputs.nixos-hardware.nixosModules.dell-xps-13-9360
        ];
      };
    };

    # Home Manager (only) users
    homeConfigurations = {
      gene = localLib.mkHomeConfig {
        system = "x86_64-linux";
        homeDirectory = "/home/gene";
        username = "gene";
      };
    };
  };
}
