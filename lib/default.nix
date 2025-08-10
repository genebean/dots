{ inputs, ... }: let
  mkDarwinHost = import ./mkDarwinHost.nix { inherit inputs; };
  mkHomeConfig = import ./mkHomeConfig.nix { inherit inputs; };
  mkNixosHost = import ./mkNixosHost.nix { inherit inputs; };
in {
  inherit (mkDarwinHost) mkDarwinHost;
  inherit (mkHomeConfig) mkHomeConfig;
  inherit (mkNixosHost) mkNixosHost;
}
