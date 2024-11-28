{ ... }: {
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    opts = {
      # make sure vim know I always have a dark terminal
      background = "dark";

      # use spaces for tabs and whatnot
      expandtab = true;
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      shiftround = true;

      # make sure all the mouse stuff is on.
      # pressing alt to hightlight + copy/paste works like it does outside of nvim
      mouse = "a";

      termguicolors = true;

      # Tips from https://github.com/folke/edgy.nvim
      # views can only be fully collapsed with the global statusline
      laststatus = 3;

      # Default splitting will cause your main splits to jump when opening an edgebar.
      # To prevent this, set `splitkeep` to either `screen` or `topline`.
      splitkeep = "screen";
    };

    # TODO
    #vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")

    #vim.wo.relativenumber = true
  };
}







