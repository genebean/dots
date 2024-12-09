return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      sync_install = false,
      ensure_installed = {
        "bash",
        "css",
        "csv",
        "diff",
        "dockerfile",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitignore",
        "go",
        "hcl",
        "hocon",
        "html",
        "javascript",
        "json",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        "passwd",
        "promql",
        "puppet",
        "python",
        "regex",
        --"pip_requirements",
        "ruby",
        "sql",
        "ssh_config",
        "terraform",
        "toml",
        "tsv",
        "typescript",
        "udev",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
    })
  end,
}