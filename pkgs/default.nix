{ inputs, pkgs }:
let
  deploy-with-retry = pkgs.callPackage ./deploy-with-retry { inherit inputs; };
  dnclient = pkgs.callPackage ./dnclient { };
  filtered-podcast-feeds = pkgs.callPackage ./filtered-podcast-feeds { };
  nixdiff = pkgs.callPackage ./nixdiff { };
  rpi4-installer = pkgs.callPackage ./rpi4-installer { inherit inputs; };
in
{
  inherit
    deploy-with-retry
    dnclient
    filtered-podcast-feeds
    nixdiff
    rpi4-installer
    ;
  default = nixdiff;
}
