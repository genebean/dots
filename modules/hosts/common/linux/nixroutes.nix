{ config, lib, ... }:
let
  hostName = config.networking.hostName;
in {
  programs.zsh.shellAliases.nixroutes =
    "cd ~/repos/dots && echo '=== Current Routes ===' && ip route show && ip -6 route show && echo '' && echo '=== New Build Routes ===' && nix eval --apply 'routes: builtins.concatStringsSep \"\\\\n\" (map (r: r.Destination + \" via \" + r.Gateway) routes)' '.#nixosConfigurations.${hostName}.config.systemd.network.networks.\"10-wan\".routes' | tr '\\\\n' '\\n'";
}
