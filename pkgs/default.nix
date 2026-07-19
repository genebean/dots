{ inputs, pkgs }:
let
  nixdiff = pkgs.callPackage ./nixdiff { };
  rpi4-installer = pkgs.callPackage ./rpi4-installer { inherit inputs; };
in
{
  inherit nixdiff rpi4-installer;
  default = nixdiff;
}
