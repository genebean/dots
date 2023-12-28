return {
  "williamboman/mason-lspconfig.nvim",
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",   -- lua
        "nil_ls",   -- nix
        "puppet",   -- puppet
        "ruff_lsp", -- python
      }
    })
  end
}

