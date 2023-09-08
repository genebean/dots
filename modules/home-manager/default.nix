{ pkgs, ... }: {
  home.stateVersion = "23.11";
  # home.packages = with pkgs; [
    #
  # ];
  home.sessionVariables = {
    CLICLOLOR = 1;
    EDITOR = "vim";
    PAGER = "less";
  };
  programs = {
    bat.enable = true;
    eza.enable = true;
    gh.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
    };
    go = {
      enable = true;
      goPath = "go";
    };
    jq.enable = true;
    k9s.enable = true;
    neovim.enable = true;
    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./files/beanbag.omp.json));
    };
    vim.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      history.save = 1000000;
      history.size = 1000000;
      initExtra = ''
        [ -f ~/.private-env ] && source ~/.private-env || echo '~/.private-env is missing'

        # Start GPG agent
        # Some tips from https://hedberg.io/yubikey-for-ssh/ helped simplify this:
        if [[ $(uname) == 'Darwin' ]]; then
          # Add GPG Suite binaries to the path:
          export PATH=/usr/local/MacGPG2/bin:$PATH
        fi

        export GPG_TTY=$(tty)

        if [[ `uname` == 'Linux' ]]; then
          alias uwgconnect='nmcli dev wifi connect SecureWest password'
          alias uwgforget='nmcli connection delete SecureWest'
          alias ykey='sudo systemctl restart pcscd && sudo pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L'
        else
          alias currentwifi='networksetup -getairportnetwork en0 |cut -d ":" -f2- | cut -d " " -f2-'
          alias uwgconnect='networksetup -setairportnetwork en0 SecureWest'
          alias uwgforget='networksetup -removepreferredwirelessnetwork en0 SecureWest'
          alias ykey='pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L'
        fi
        if [[ `uname` != 'Linux' ]]; then
          function otpon() {
                  osascript -e 'tell application "yubiswitch" to KeyOn'
          }
          function otpoff() {
                  osascript -e 'tell application "yubiswitch" to KeyOff'
          }
        fi
      '';
      oh-my-zsh = {
        enable = true;
        plugins = [
          "bundler"
          "gem"
          "git"
          "github"
          "history"
          "kubectl"
          "macos"
          "pip"
          "terraform"
          "vagrant"
          "vscode"
        ];
      };
      shellAliases = {
        beo = "bundle exec onceover run spec --trace --force";
        biv = "bundle install --path=vendor/bundle";
        ce = "code-exploration";
        gbc = ''
          git branch --merged | command grep -vE "^(\*|\s*(main|master|develop|production)\s*$)" | command xargs -n 1 git branch -d
        '';
        gitextract = "git log --pretty=email --patch-with-stat --reverse --full-index --binary --";
        gpge = "gpg2 --encrypt --sign --armor -r ";
        hubpr = "hub pull-request --push --browse";
        pssh = "ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o KexAlgorithms=+diffie-hellman-group1-sha1 -i ~/.ssh/id_rsa-acceptance";
        sal = "ssh-add -L";
        st = "open -a SourceTree";
        sz = "source ~/.zshrc";
        usegpg = "killall ssh-agent; export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) && gpgconf --launch gpg-agent";
        usessh = "gpgconf --kill gpg-agent";
      };
    }; # end zsh
  };
}
