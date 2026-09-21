{
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
        "olm-3.2.16"
        "python3.12-ecdsa-0.19.1"
      ];
    };
    overlays = [
      (final: prev: {
        dnclient = prev.callPackage ../pkgs/dnclient { };
        filtered-podcast-feeds = prev.callPackage ../pkgs/filtered-podcast-feeds { };
        nixdiff = prev.callPackage ../pkgs/nixdiff { };
      })
    ];
  };
}
