return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = true,
        -- theme = "dracula-nvim",
      },
      sections = {
        lualine_a = {
          {
            "filename",
            path = 1,
          },
        },
      },
    })
  end,
}
