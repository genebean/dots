{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "0.9.6";
in
stdenv.mkDerivation {
  pname = "dnclient";
  inherit version;

  src = fetchurl {
    url = "https://dl.defined.net/10c23c2d/v${version}/linux/amd64/dnclient";
    hash = "sha256-Z/uvC89Dt8r5crkahkUhrCnSj7Ae8N54B5TZvgchtPA=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    install -Dm755 $src $out/bin/dnclient
  '';

  meta = {
    description = "Managed Nebula VPN client from Defined Networking";
    homepage = "https://defined.net";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    mainProgram = "dnclient";
  };
}
