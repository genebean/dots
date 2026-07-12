{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.vim;
in
{
  options.genebean.programs.vim = {
    enable = lib.mkEnableOption "Vim text editor";
  };

  config = lib.mkIf cfg.enable {
    programs.vim = {
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
  };
}
