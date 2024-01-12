return {
  "akinsho/bufferline.nvim",
  after = "catppuccin",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "*",
  config = function()
    -- Get the color pallet of the theme flavor I am using
    local color_palette = require("catppuccin.palettes").get_palette("frappe")

    -- Set variables to use the color they'd use if the background was not transparent
    local bg_highlight = color_palette.crust
    local separator_fg = color_palette.crust

    require("bufferline").setup({
      highlights = require("catppuccin.groups.integrations.bufferline").get({
        -- Copy settings from Catppuccin bufferline integration and override just the
        -- part that is  needed to make it look like it would if the background was not
        -- set to transparent in catppuccin.lua
        -- https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/bufferline.lua
        custom = {
          all = {
            -- this makes the background behind the tabs contrast with the tabs themselves
            fill = { bg = bg_highlight },

            -- separators
            -- I am only overriding the foreground as that is what makes the tabs look correct
            separator = { fg = separator_fg },
            separator_visible = { fg = separator_fg },
            separator_selected = { fg = separator_fg },
            offset_separator = { fg = separator_fg },
          },
        },
      }),
      options = {
        mode = "buffers",
        separator_style = "slant",
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true,
          },
        },
        diagnostics = "nvim_lsp",
      },
    })
  end,
}
