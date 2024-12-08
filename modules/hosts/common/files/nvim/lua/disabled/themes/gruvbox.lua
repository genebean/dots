return  {
  "ellisonleao/gruvbox.nvim",
  priority = 1000 ,
  config = function ()
    require("gruvbox").setup()

    vim.o.background = "dark"
    vim.o.termguicolors = true
    vim.cmd.colorscheme "gruvbox"
  end
}
