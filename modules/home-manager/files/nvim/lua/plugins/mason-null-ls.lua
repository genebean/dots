return {
  "jay-babu/mason-null-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "nvimtools/none-ls.nvim",
  },
  config = function()
    require("mason-null-ls").setup({
      ensure_installed = {
        "prettier", -- HTML, JS, JSON, etc.
        "ruff",     -- Pyhton
        "stylua",   -- LUA
      },
    })
  end,
}
