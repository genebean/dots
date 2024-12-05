{ inputs, ... }: let
  mkNixosHost = import ./mkNixosHost.nix { inherit inputs; };
in {
  inherit (mkNixosHost)
    mkNixosHost
    ;
}