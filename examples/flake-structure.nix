{
  inputs = {};
  outputs = inputs@{}: let
    darwinHostConfig = { system, hostname, username, additionalModules, additionalSpecialArgs }:
      nix-darwin.lib.darwinSystem { };

    nixosHostConfig = { system, hostname, username, additionalModules, additionalSpecialArgs }:
      nixpkgs.lib.nixosSystem { };
    
    linuxHomeConfig = { system, hostname, username, additionalModules, additionalSpecialArgs }:
      home-manager.lib.homeManagerConfiguration { };

  in {
    # Darwin (macOS) hosts
    darwinConfigurations = {
      mightymac = darwinHostConfig {
        system = "aarch64-darwin";
        hostname = "mightymac";
        username = "gene.liverman";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
    };

    # NixOS hosts
    nixosConfigurations = {
      rainbow-planet = nixosHostConfig {
        system = "x86_64-linux";
        hostname = "rainbow-planet";
        username = "gene";
        additionalModules = [
          nixos-hardware.nixosModules.dell-xps-13-9360
        ];
        additionalSpecialArgs = {};
      };
    };

    # Home Manager (only) users
    homeConfigurations = {
      gene = linuxHomeConfig {
        system = "x86_64-linux";
        hostname = "mini-watcher";
        username = "gene";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
    };
  };
}