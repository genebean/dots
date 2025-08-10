{ inputs, ... }: {
  mkHomeConfig = {
    system ? "x86_64-linux",
    homeDirectory,
    username,
  }: inputs.home-manager.lib.homeManagerConfiguration {
    extraSpecialArgs = { inherit inputs homeDirectory username; };

    pkgs = inputs.nixpkgs.legacyPackages.${system};

    # Specify your home configuration modules here, for example,
    # the path to your home.nix.
    modules = [
      ./nixpkgs-settings.nix
      ../modules/hosts/common
      ../modules/hosts/home-manager-only
      ../modules/hosts/home-manager-only/home-${username}.nix

      {
        home = {
          username = "${username}";
          homeDirectory = "${homeDirectory}";
        };
      }

      inputs.sops-nix.homeManagerModules.sops
    ];
  };
}