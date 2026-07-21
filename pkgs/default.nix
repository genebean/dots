{ inputs, pkgs }:
let
  deploy-with-retry = pkgs.callPackage ./deploy-with-retry { inherit inputs; };
  nixdiff = pkgs.callPackage ./nixdiff { };
  rpi4-installer = pkgs.callPackage ./rpi4-installer { inherit inputs; };
in
{
  inherit deploy-with-retry nixdiff rpi4-installer;
  default = nixdiff;
}
