{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-terraform = {
      url = "github:stackbuilders/nixpkgs-terraform";
      # inputs.nixpkgs-1_6.follows = "nixpkgs";
      # inputs.nixpkgs-1_9.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs: {
    nixosConfigurations = {
      rainbow-planet = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./nixpkgs-settings.nix
          inputs.home-manager.nixosModules.home-manager
        ];
      };
    };
  };
}
