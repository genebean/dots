{ stdenv, bundlerEnv, fetchFromGitHub, ruby }:
let
  # the magic which will include gemset.nix
  gems = bundlerEnv {
    name = "puppet-editor-services-env";
    inherit ruby;
    gemdir = ./.;
  };
in stdenv.mkDerivation {
  name = "puppet-editor-services";
  src = fetchFromGitHub {
    owner = "puppetlabs";
    repo = "puppet-editor-services";
    rev = "v2.0.4";
    hash = "sha256-bSLOtoOot118YaqF/23unMsOIQq+BdGsZa3JMg1k3Tk=";
  };
  buildInputs = [gems ruby];
  installPhase = ''
    mkdir -p $out/{bin,share/puppet-editor-services}
    cp -r * $out/share/puppet-editor-services

    debugserver=$out/bin/puppet-debugserver
# we are using bundle exec to start in the bundled environment
    cat > $debugserver <<EOF
#!/bin/sh -e
exec ${gems}/bin/bundle exec ${ruby}/bin/ruby $out/share/puppet-editor-services/puppet-debugserver "\$@"
EOF
    chmod +x $debugserver

    languageserver=$out/bin/puppet-languageserver
# we are using bundle exec to start in the bundled environment
    cat > $languageserver <<EOF
#!/bin/sh -e
exec ${gems}/bin/bundle exec ${ruby}/bin/ruby $out/share/puppet-editor-services/puppet-languageserver "\$@"
EOF
    chmod +x $languageserver

    sidecar=$out/bin/puppet-languageserver-sidecar
# we are using bundle exec to start in the bundled environment
    cat > $sidecar <<EOF
#!/bin/sh -e
exec ${gems}/bin/bundle exec ${ruby}/bin/ruby $out/share/puppet-editor-services/puppet-languageserver-sidecar "\$@"
EOF
    chmod +x $sidecar
  '';
}