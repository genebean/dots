{ inputs, ... }: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "olm-3.2.16" "electron-27.3.11" ];
    };
    overlays = [ inputs.nixpkgs-terraform.overlays.default ];
  };
}
