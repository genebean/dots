return {
	{
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
					"stylua", -- LUA
				},
			})
		end,
	},
	{
		-- none-ls replaces null_ls... it's weird
		"nvimtools/none-ls.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					null_ls.builtins.completion.spell,
					null_ls.builtins.diagnostics.puppet_lint,
					null_ls.builtins.diagnostics.rubocop,
					null_ls.builtins.formatting.prettier,
					null_ls.builtins.formatting.puppet_lint,
					null_ls.builtins.formatting.rubocop,
					null_ls.builtins.formatting.stylua,
				},
			})

			vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
		end,
	},
}
