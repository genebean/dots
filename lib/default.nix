{ inputs, nixpkgs, nixpkgs-unstable, compose2nix, disko, flox, genebean-omp-themes,
    home-manager, nix-darwin, nix-flatpak, nix-homebrew, nixos-cosmic,
    nixos-hardware, nixpkgs-terraform, simple-nixos-mailserver, sops-nix, ...
}: let
  nixosHostConfig = import ./nixosHostConfig.nix { inherit inputs nixpkgs nixpkgs-unstable compose2nix disko flox genebean-omp-themes
    home-manager nix-darwin nix-flatpak nix-homebrew nixos-cosmic
    nixos-hardware nixpkgs-terraform simple-nixos-mailserver sops-nix; };
in {
  inherit (nixosHostConfig)
    nixosHostConfig
    ;
}