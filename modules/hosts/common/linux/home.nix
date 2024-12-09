{ pkgs, ... }: {
  home.packages = with pkgs; [
    fastfetch
  ];

  programs = {
    # Linux-specific aliases
    zsh.shellAliases = {
      nixboot = "sudo nixos-rebuild boot --flake ~/repos/dots && echo 'Time to reboot!'";
      nixdiff = "cd ~/repos/dots && nixos-rebuild build --flake . && nvd diff /run/current-system result";
      nixup = "sudo nixos-rebuild switch --flake ~/repos/dots";
      uwgconnect = "nmcli dev wifi connect SecureWest password";
      uwgforget = "nmcli connection delete SecureWest";
      ykey = "sudo systemctl restart pcscd && sudo pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L";
    };
  };
}
