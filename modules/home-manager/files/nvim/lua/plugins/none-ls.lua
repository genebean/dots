return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        null_ls.builtins.completion.spell,
        null_ls.builtins.diagnostics.puppet_lint,
        null_ls.builtins.diagnostics.rubocop,
        null_ls.builtins.diagnostics.ruff,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.puppet_lint,
        null_ls.builtins.formatting.rubocop,
        null_ls.builtins.formatting.ruff_format,
        null_ls.builtins.formatting.stylua,
      },
    })

    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end,
}
