{ inputs, ... }: let
  mkDarwinHost = import ./mkDarwinHost.nix { inherit inputs; };
  mkNixosHost = import ./mkNixosHost.nix { inherit inputs; };
in {
  inherit (mkDarwinHost)
    mkDarwinHost
    ;
  inherit (mkNixosHost)
    mkNixosHost
    ;
}