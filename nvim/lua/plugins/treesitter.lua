return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup()

    -- Install parsers (async, no-op if already installed)
    require("nvim-treesitter").install({
      "bash", "c", "css", "dockerfile", "go", "gomod",
      "html", "javascript", "json", "lua", "luadoc",
      "markdown", "markdown_inline", "python", "query",
      "regex", "rust", "toml", "tsx", "typescript",
      "vim", "vimdoc", "yaml",
    })

    -- Enable treesitter highlighting for all supported filetypes
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        -- Only start if a parser is available for this filetype
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    -- Enable treesitter-based indentation
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
