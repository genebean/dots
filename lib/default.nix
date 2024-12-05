{ inputs, ... }: let
  nixosHostConfig = import ./nixosHostConfig.nix { inherit inputs; };
in {
  inherit (nixosHostConfig)
    nixosHostConfig
    ;
}