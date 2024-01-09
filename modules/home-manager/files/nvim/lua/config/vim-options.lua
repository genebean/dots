vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- make sure vim know I always have a dark terminal
vim.opt.background = "dark"

-- use spaces for tabs and whatnot
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true

-- make sure all the mouse stuff is on.
-- pressing alt to hightlight + copy/paste works like it does outside of nvim
vim.opt.mouse = "a"

vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")

vim.wo.relativenumber = true

vim.o.termguicolors = true
