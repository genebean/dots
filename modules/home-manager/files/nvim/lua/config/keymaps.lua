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

vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
