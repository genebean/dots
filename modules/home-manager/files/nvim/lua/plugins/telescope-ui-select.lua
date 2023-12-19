return {
  "nvim-telescope/telescope-ui-select.nvim",
  config = function ()
    -- This is your opts table
    require("telescope").setup({
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown({
            -- even more opts
          })
        }
      }
    })
    -- load_extension, somewhere after setup function:
    require("telescope").load_extension("ui-select")
  end
}

