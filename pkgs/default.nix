{ inputs, pkgs }:
let
  bcachefs-installer-iso = pkgs.callPackage ./bcachefs-installer-iso { inherit inputs; };
  bcachefs-kexec-installer = pkgs.callPackage ./bcachefs-kexec-installer { inherit inputs; };
  deploy-with-retry = pkgs.callPackage ./deploy-with-retry { inherit inputs; };
  dnclient = pkgs.callPackage ./dnclient { };
  filtered-podcast-feeds = pkgs.callPackage ./filtered-podcast-feeds { };
  nixdiff = pkgs.callPackage ./nixdiff { };
  rpi4-installer = pkgs.callPackage ./rpi4-installer { inherit inputs; };
in
{
  inherit
    bcachefs-installer-iso
    bcachefs-kexec-installer
    deploy-with-retry
    dnclient
    filtered-podcast-feeds
    nixdiff
    rpi4-installer
    ;
  default = nixdiff;
}
