{ inputs, ... }: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
        "olm-3.2.16"
        "python3.12-ecdsa-0.19.1"
      ];
    };
    overlays = [ inputs.nixpkgs-terraform.overlays.default ];
  };
}
