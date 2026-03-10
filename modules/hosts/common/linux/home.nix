{ pkgs, ... }: {
  home.packages = with pkgs; [
    fastfetch
  ];

  programs = {
    # Linux-specific aliases
    zsh.shellAliases = {
      nixboot = "sudo nixos-rebuild boot --flake ~/repos/dots && echo 'Time to reboot!'";
      nixdiff = "cd ~/repos/dots && nixos-rebuild build --flake . && nvd diff /run/current-system result";
      nixroutes = "cd ~/repos/dots && echo '=== Current Routes ===' && ip route show && ip -6 route show && echo '' && echo '=== New Build Routes ===' && nix eval --apply 'routes: builtins.concatStringsSep \"\\n\" (map (r: r.Destination + \" via \" + r.Gateway) routes)' '.#nixosConfigurations.$(hostname).config.systemd.network.networks.\"10-wan\".routes'";
      nixup = "sudo nixos-rebuild switch --flake ~/repos/dots";
      uwgconnect = "nmcli dev wifi connect SecureWest password";
      uwgforget = "nmcli connection delete SecureWest";
      ykey = "sudo systemctl restart pcscd && sudo pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L";
    };
  };
}
