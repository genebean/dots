return {
  "catppuccin/nvim",
  name = "catppuccin",
  flavour = "frappe", -- latte, frappe, macchiato, mocha
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      transparent_background = true,
      color_overrides = {
        frappe = {
          base = "#07042B",
          mantle = "#0c0746",
          crust = "#10095d",
          rosewater = "#FF7F7F", -- used for cursor
        },
      },
      custom_highlights = function(colors)
        return {
          Comment = { fg = colors.subtext0 },
          LineNr = { fg = colors.subtext0 },
        }
      end,
    })
    vim.cmd.colorscheme("catppuccin")
  end,

  --[[
  -- original palette from frappe:
	rosewater = "#f2d5cf",
	flamingo = "#eebebe",
	pink = "#f4b8e4",
	mauve = "#ca9ee6",
	red = "#e78284",
	maroon = "#ea999c",
	peach = "#ef9f76",
	yellow = "#e5c890",
	green = "#a6d189",
	teal = "#81c8be",
	sky = "#99d1db",
	sapphire = "#85c1dc",
	blue = "#8caaee",
	lavender = "#babbf1",
	text = "#c6d0f5",
	subtext1 = "#b5bfe2",
	subtext0 = "#a5adce",
	overlay2 = "#949cbb",
	overlay1 = "#838ba7",
	overlay0 = "#737994",
	surface2 = "#626880",
	surface1 = "#51576d",
	surface0 = "#414559",
	base = "#303446",
	mantle = "#292c3c",
	crust = "#232634",
  --]]
}
