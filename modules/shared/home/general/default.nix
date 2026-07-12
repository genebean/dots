{
  config,
  inputs,
  pkgs,
  ...
}:
{
  genebean = {
    programs = {
      claude-code.enable = true;
      nixdiff.enable = true;
      powershell.enable = true;
      sops.enable = true;
    };
    services = {
      tailscale.enable = true;
    };
  };

  home = {
    packages = with pkgs; [
      btop
      bundix
      cargo
      cheat
      colordiff
      deadnix
      # dogdns # seems this is now unmaintained :(
      doggo
      dos2unix
      duf
      dust
      (fastfetch.override { enlightenmentSupport = false; })
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
      inputs.nix-auth.packages.${stdenv.hostPlatform.system}.default
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
      nurl
      nvd
      nixfmt-tree
      onefetch
      pre-commit
      puppet-lint
      rename
      ruby
      subversion
      statix
      tldr
      tree
      trippy
      vimv
      watch
      wget
      yq-go
    ];
    sessionVariables = {
      CLICLOLOR = 1;
      PAGER = "less";
    };
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
    diff-so-fancy = {
      enable = true;
      enableGitIntegration = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    eza.enable = true;
    fzf.enable = true;
    genebean-neovim.enable = true;
    gh.enable = true;
    git = {
      enable = true;
      ignores = [
        "*~"
        "*.swp"
        ".DS_Store"
      ];
      lfs.enable = true;
      package = pkgs.gitFull;
      settings = {
        diff.sopsdiffer.textconv = "sops --config /dev/null --decrypt";

        init = {
          defaultBranch = "main";
        };
        commit = {
          gpgsign = true;
        };
        gpg = {
          format = "ssh";
          ssh = {
            allowedSignersFile = "${config.home.homeDirectory}/.config/git/allowed_signers";
          };
        };
        merge = {
          conflictStyle = "diff3";
          tool = "meld";
        };
        pull = {
          rebase = false;
        };
        user = {
          name = "Gene Liverman";
          signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        };
      };
    }; # end git
    irssi.enable = true;
    jq.enable = true;
    nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/repos/dots";
    };
    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromJSON (
        builtins.unsafeDiscardStringContext (
          builtins.readFile (inputs.genebean-omp-themes + "/beanbag.omp.json")
        )
      );
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
    zellij = {
      enable = true;
      enableZshIntegration = false;
    };
  }; # end programs
}
