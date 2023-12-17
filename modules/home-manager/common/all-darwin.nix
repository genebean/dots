{ pkgs, genebean-omp-themes, ... }: {
  # dawrwin-specific shell config
  programs.zsh = {
    initExtra = ''
      function otpon() {
        osascript -e 'tell application "yubiswitch" to KeyOn'
      }
      function otpoff() {
        osascript -e 'tell application "yubiswitch" to KeyOff'
      }

      # Include Puppet's normal bin folder since it is installed via Homebrew
      export PATH=$PATH:/opt/puppetlabs/bin
      export PATH=$PATH:/opt/puppetlabs/pdk/bin
      export PATH=$PATH:/opt/puppetlabs/puppet/bin
    '';
    oh-my-zsh.plugins = [ "macos" ];
    shellAliases = {
      currentwifi = "networksetup -getairportnetwork en0 |cut -d ':' -f2- | cut -d ' ' -f2-";
      nixup = "darwin-rebuild switch --flake ~/repos/dots";
      uwgconnect = "networksetup -setairportnetwork en0 SecureWest";
      uwgforget = "networksetup -removepreferredwirelessnetwork en0 SecureWest";
      ykey = "pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L";
    };
  };
}
