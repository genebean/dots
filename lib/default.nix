{ inputs, ... }:
let
  mkDarwinHost = import ./mkDarwinHost.nix { inherit inputs; };
  mkDeployNode = import ./mkDeployNode.nix { inherit inputs; };
  mkHomeConfig = import ./mkHomeConfig.nix { inherit inputs; };
  mkNixosHost = import ./mkNixosHost.nix { inherit inputs; };
  genebeanLib = {
    isDarwin = false;
    isHMOnly = false;
    isNixOS = false;
  };
in
{
  inherit (mkDarwinHost) mkDarwinHost;
  inherit (mkDeployNode) mkDeployNode;
  inherit (mkHomeConfig) mkHomeConfig;
  inherit (mkNixosHost) mkNixosHost;
  inherit genebeanLib;
}
