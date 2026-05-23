return {
  "utilyre/sentiment.nvim",
  version = "*",
  event = "VeryLazy",
  init = function()
    vim.g.loaded_matchparen = 1
  end,
  config = function()
    require("sentiment").setup({
      included_buftypes = { [""] = true },
      excluded_filetypes = {},
      delay = 50,
      limit = 100,
      pairs = {
        { "(", ")" },
        { "{", "}" },
        { "[", "]" },
      },
    })

    -- Make matching bracket highly visible with theme-aware gold accent
    local function set_match_hl()
      vim.api.nvim_set_hl(0, "MatchParen", {
        fg = "#1a1510",
        bg = "#ffb454",
        bold = true,
      })
    end
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_match_hl })
    set_match_hl()
  end,
}
