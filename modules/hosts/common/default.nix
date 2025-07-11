{ inputs, pkgs, ... }: let
  sqlite_lib = if builtins.elem pkgs.system [
                 "aarch64-darwin"
                 "x86_64-darwin"
               ]
               then "libsqlite3.dylib"
               else "libsqlite3.so";
in {
  home.packages = with pkgs; [
    bundix
    cargo
    cheat
    colordiff
    dogdns
    dos2unix
    du-dust
    duf
    esptool
    fd
    f2
    git-filter-repo
    glab
    glow
    gomuks
    gotop
    htop
    httpie
    hub
    jq
    lazydocker
    lazygit
    lua-language-server
    minicom
    mtr
    nil
    nix-search
    nix-zsh-completions
    nodejs
    nodePackages.npm
    nurl
    nvd
    onefetch
    powershell
    pre-commit
    puppet-lint
    rename
    ruby
    subversion
    tldr
    tree
    trippy
    vimv
    watch
    wget
    yq-go
  ];
  home.sessionVariables = {
    CLICLOLOR = 1;
    PAGER = "less";
  };
  programs = {
    atuin = {
      enable = true;
      settings = {
        ctrl_n_shortcuts = true; # Use Ctrl-0 .. Ctrl-9 instead of Alt-0 .. Alt-9 UI shortcuts
        enter_accept = true; # press tab to edit command before running
        filter_mode_shell_up_key_binding = "host"; # or global, host, directory, etc
        sync_address = "https://atuin.home.technicalissues.us";
        sync_frequency = "15m";

      };
    };
    bat = {
      enable = true;
      config = {
        theme = "Catppuccin-frappe";
      };
      themes = {
        Catppuccin-frappe = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
            hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
          };
          file = "Catppuccin-frappe.tmTheme";
        };
      };
    };
    bottom.enable = true;
    broot.enable = true;
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    eza.enable = true;
    fzf.enable = true;
    gh.enable = true;
    git = {
      enable = true;
      diff-so-fancy.enable = true;
      extraConfig = {
        diff.sopsdiffer.textconv = "sops --config /dev/null --decrypt";
      };
      ignores = [
        "*~"
        "*.swp"
        ".DS_Store"
      ];
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
    irssi.enable = true;
    jq.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      extraLuaConfig = ''
        -- NOTE: This will get the OS from Lua:
        -- print(vim.loop.os_uname().sysname)

        -- setup lazy.nvim
        local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
        vim.opt.rtp:prepend(lazypath)

        -- hack to deal with bug in telescope-cheat.nvim
        -- https://github.com/nvim-telescope/telescope-cheat.nvim/issues/7
        local cheat_dbdir = vim.fn.stdpath "data" .. "/databases"
        if not vim.loop.fs_stat(cheat_dbdir) then
          vim.loop.fs_mkdir(cheat_dbdir, 493)
        end

        -- load additional settings
        require("config.vim-options")
        require("lazy").setup("plugins")

        -- tell sqlite.lua where to find the bits it needs
        vim.g.sqlite_clib_path = '${pkgs.sqlite.out}/lib/${sqlite_lib}'

      '';
      extraPackages = with pkgs; [
        gcc    # needed so treesitter can do compiling
        sqlite # needed by sqlite.lua used by telescope-cheat
      ];
      plugins = [ pkgs.vimPlugins.lazy-nvim ]; # let lazy.nvim manage every other plugin
    };
    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile (inputs.genebean-omp-themes + "/beanbag.omp.json")));
      #useTheme = "amro";
      #useTheme = "montys";
    };
    ripgrep.enable = true;
    tmux = {
      enable = true;
      historyLimit = 100000;
      mouse = true;
      tmuxinator.enable = true;
      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        {
          plugin = dracula;
          extraConfig = ''
            set -g @dracula-show-battery false
            set -g @dracula-show-powerline true
            set -g @dracula-refresh-rate 10
            '';
        }
      ];
      extraConfig = ''
        set -g status-position top
      '';
    };
    vim = {
      enable = true;
      defaultEditor = false;
      plugins = with pkgs.vimPlugins; [
        syntastic
        tabular
        tlib_vim
        vim-addon-mw-utils
        vim-airline
        vim-airline-themes
        vim-flog
        vim-fugitive
        vim-json
        vim-markdown
        vim-nix
        vim-puppet
        vim-ruby
        vim-snipmate
        vim-snippets
        vim-tmux-navigator
        vim-yaml
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
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      history.save = 1000000;
      history.size = 1000000;
      initContent = ''
        [ -f ~/.private-env ] && source ~/.private-env || echo '~/.private-env is missing'
        [ -f ~/.gitconfig-local ] || echo '~/.gitconfig-local is missing. Create it and set user.email'

        # Start GPG agent
        # Some tips from https://hedberg.io/yubikey-for-ssh/ helped simplify this:
        if [[ $(uname) == 'Darwin' ]]; then
          # Add GPG Suite binaries to the path:
          export PATH=/usr/local/MacGPG2/bin:$PATH
        fi

        export GPG_TTY=$(tty)
        function nv() {
          # Assumes all configs exist in directories named ~/.config/nvim-*
          local config=$(fd --max-depth 1 --glob 'nvim*' ~/.config | fzf --prompt="Neovim Configs > " --height=~50% --layout=reverse --border --exit-0)

          # If I exit fzf without selecting a config, don't open Neovim
          [[ -z $config ]] && echo "No config selected" && return

          # Open Neovim with the selected config
          NVIM_APPNAME=$(basename $config) nvim $*
        }

        function svndiffless() {
          svn diff "$@" |diff-so-fancy |less -R
        }

        function svndiffless-nows() {
          svn diff -x -w "$@" |diff-so-fancy |less -R
        }

        # unset oh-my-zsh's gk so that gk can refer to the gitkraken-cli
        unalias gk
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
          "pip"
          "terraform"
          "vagrant"
          "vscode"
        ];
      };
      shellAliases = {
        bcrr = "bolt command run --run-as root --sudo-password-prompt";
        bcrrs = "bcrr --stream --no-verbose";
        beo = "bundle exec onceover run spec --trace --force";
        biv = "bundle install --path=vendor/bundle";
        bottom = "echo 'To run bottom, the command is btm'";
        ce = "code-exploration";
        dots = "cd ~/repos/dots";
        gbc = ''
          git branch --merged | command grep -vE "^(\*|\s*(main|master|develop|production|qa)\s*$)" | command xargs -n 1 git branch -d
        '';
        gitextract = "git log --pretty=email --patch-with-stat --reverse --full-index --binary --";
        gpge = "gpg2 --encrypt --sign --armor -r ";
        hubpr = "hub pull-request --push --browse";
        nvdots = "NVIM_APPNAME=nvim-dots nvim";
        nve = "nvdots ~/repos/dots/modules/home-manager/files/nvim/lua";
        pssh = "ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o KexAlgorithms=+diffie-hellman-group1-sha1 -i ~/.ssh/id_rsa-acceptance";
        sal = "ssh-add -L";
        sshnull = "ssh -o UserKnownHostsFile=/dev/null";
        st = "open -a SourceTree";
        sz = "source ~/.zshrc";
        trippy = "echo 'To run trippy, the command is trip'";
        usegpg = "killall ssh-agent; export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) && gpgconf --launch gpg-agent";
        usessh = "gpgconf --kill gpg-agent";
      };
    }; # end zsh
  }; # end programs

  home.file = {
    ".config/nvim/lua/config" = {
      source = ./files/nvim/lua/config;
      recursive = true;
    };
    ".config/nvim/lua/plugins" = {
      source = ./files/nvim/lua/plugins;
      recursive = true;
    };
    ".config/powershell/Microsoft.PowerShell_profile.ps1".source = ./files/Microsoft.PowerShell_profile.ps1;
    ".config/powershell/Microsoft.VSCode_profile.ps1".source = ./files/Microsoft.PowerShell_profile.ps1;
  };
}
