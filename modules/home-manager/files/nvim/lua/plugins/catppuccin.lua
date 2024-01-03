return {
  "catppuccin/nvim",
  name = "catppuccin",
  flavour = "frappe", -- latte, frappe, macchiato, mocha
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("catppuccin")
  end,
}
