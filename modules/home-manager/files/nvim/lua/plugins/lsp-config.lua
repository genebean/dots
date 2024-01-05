return {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", -- lua
          "nil_ls", -- nix
          "puppet", -- puppet
          "ruff_lsp", -- python
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local on_attach = function(_, _)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
        vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, {})
        vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      end

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      lspconfig.nil_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      local puppet_languageserver = vim.fn.expand(
        "$HOME/.local/share/nvim/mason/packages/puppet-editor-services/libexec/puppet-languageserver"
      )

      lspconfig.puppet.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { puppet_languageserver, "--feature-flags=puppetstrings" },
        settings = { puppet = { editorServices = { formatOnType = { enable = true } } } },
      })
      lspconfig.ruff_lsp.setup({ on_attach = on_attach })
    end,
  },
}
