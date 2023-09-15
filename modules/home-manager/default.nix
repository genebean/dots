{ pkgs, genebean-omp-themes, ... }: {
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    colordiff
    dog
    dos2unix
    du-dust
    element-desktop
    gotop
    htop
    hub
    jq
    meld
    mtr
    nix-zsh-completions
    nurl
    powershell
    rename
    slack
    subversion
    tree
    watch
    wget
    yq
    zoom-us
  ];
  home.sessionVariables = {
    CLICLOLOR = 1;
    PAGER = "less";
  };
  programs = {
    bat = {
      enable = true;
      config = {
        theme = "Catppuccin-frappe";
      };
      themes = {
        Catppuccin-frappe = builtins.readFile (pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
          hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        } + "/Catppuccin-frappe.tmTheme");
      };
    };
    eza.enable = true;
    gh.enable = true;
    git = {
      enable = true;
      delta.enable = true;
      includes = [ { path = "~/.gitconfig-local"; }];
      lfs.enable = true;
      package = pkgs.gitAndTools.gitFull;
      userName = "Gene Liverman";
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        merge = {
	  conflictStyle = "diff3";
          tool = "meld";
        };
        pull = {
          rebase = false;
        };
      };
    }; # end git
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
      settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile (genebean-omp-themes + "/beanbag.omp.json")));
    };
    vim = {
      enable = true;
      defaultEditor = true;
      plugins = with pkgs.vimPlugins; [
        vim-json
        vim-snipmate
        tabular
        vim-snippets
        vim-nix
        vim-addon-mw-utils
        vim-yaml
        vim-flog
        vim-puppet
        tlib_vim
        vim-fugitive
        vim-airline
        vim-airline-themes
        vim-ruby
        syntastic
      ];
      settings = {
        background = "dark";
        expandtab = true;
      };
      extraConfig = ''
        set nocompatible                              " be iMproved, required
        filetype plugin indent on                     " required for plugins to be able to adjust indent
        syntax on                                     " enable syntax highlighting
        set encoding=utf-8
        set termencoding=utf-8
        set t_Co=256                                  " tell vim we have 256 colors to work with

        set autoindent                                " automatically indent new lines
        set backspace=2                               " make backspace work like most other programs
        set fillchars+=stl:\ ,stlnc:\                 " fix added per powerline troubleshooting docs
        set laststatus=2                              " Always display the status line in all windows
        set noshowmode                                " Hide the default mode text (e.g. -- INSERT -- below the status line)
        set smarttab                                  " helps with expanding tabs to spaces (I think)
        set statusline+=%{FugitiveStatusline()}       " get git info via fugitive plugin
        set statusline+=%#warningmsg#                 " recommended setting from syntastic plugin
        set statusline+=%{SyntasticStatuslineFlag()}  " recommended setting from syntastic plugin
        set statusline+=%*                            " recommended setting from syntastic plugin

        " This has to come after colorscheme, if defined, to not be masked
        highlight ColorColumn ctermbg=232             " set the color to be used for guidelines
        let &colorcolumn=join(range(81,999),",")      " change the background color of everything beyond 80 characters

        let g:snipMate = { 'snippet_version' : 1 }

        " settings for the syntastic plugin
        let g:syntastic_always_populate_loc_list = 1
        let g:syntastic_auto_loc_list            = 1
        let g:syntastic_check_on_open            = 1
        let g:syntastic_check_on_wq              = 0
        let g:syntastic_enable_signs             = 1
        let g:syntastic_ruby_checkers            = ['rubocop']
        let g:syntastic_quiet_messages           = {'level': 'warnings'}

        " don't wrap text in markdown files
        let g:vim_markdown_folding_disabled      = 1

        " settings for vim-airline
        let g:airline_theme='badwolf'
        let g:airline_powerline_fonts = 1
      '';
    };
    vscode = {
      enable = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      history.save = 1000000;
      history.size = 1000000;
      initExtra = ''
        [ -f ~/.private-env ] && source ~/.private-env || echo '~/.private-env is missing'
        [ -f ~/.gitconfig-local ] || echo '~/.gitconfig-local is missing. Create it and set user.email'

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
  }; # end programs

  home.file = {
    ".config/powershell/Microsoft.PowerShell_profile.ps1".source = ./files/Microsoft.PowerShell_profile.ps1;
    ".config/powershell/Microsoft.VSCode_profile.ps1".source = ./files/Microsoft.PowerShell_profile.ps1;
  };
}
