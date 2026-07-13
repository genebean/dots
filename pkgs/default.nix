{ pkgs, self }:
let
  nixdiff = pkgs.callPackage ./nixdiff { };
in
{
  inherit nixdiff;
  default = nixdiff;
}
// pkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
  kiosk-gene-desk-sdImage = pkgs.callPackage ./kiosk-gene-desk-sdImage.nix { inherit self; };
}
