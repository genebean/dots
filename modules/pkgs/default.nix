{ pkgs, ... }: {
  puppet-editor-services = pkgs.callPackage ./puppet-editor-services { };
}