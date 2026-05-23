return {
  "alexpasmantier/tv.nvim",
  config = function()
    local h = require("tv").handlers

    require("tv").setup({
      layout = "landscape",
      window = {
        width = 0.8,
        height = 0.8,
        border = "rounded",
        title = " tv.nvim ",
        title_pos = "center",
      },
      channels = {
        files = {
          keybinding = "<C-p>",
          handlers = {
            ["<CR>"] = h.open_as_files,
            ["<C-q>"] = h.send_to_quickfix,
            ["<C-s>"] = h.open_in_split,
            ["<C-v>"] = h.open_in_vsplit,
            ["<C-y>"] = h.copy_to_clipboard,
          },
        },
        text = {
          keybinding = "<leader><leader>",
          handlers = {
            ["<CR>"] = h.open_at_line,
            ["<C-q>"] = h.send_to_quickfix,
            ["<C-s>"] = h.open_in_split,
            ["<C-v>"] = h.open_in_vsplit,
            ["<C-y>"] = h.copy_to_clipboard,
          },
        },
        ["git-log"] = {
          keybinding = "<leader>gl",
          handlers = {
            ["<CR>"] = function(entries, config)
              if #entries > 0 then
                vim.cmd("enew | setlocal buftype=nofile bufhidden=wipe")
                vim.cmd("silent 0read !git show " .. vim.fn.shellescape(entries[1]))
                vim.cmd("1delete _ | setlocal filetype=git nomodifiable")
                vim.cmd("normal! gg")
              end
            end,
            ["<C-y>"] = h.copy_to_clipboard,
          },
        },
        ["git-branch"] = {
          keybinding = "<leader>gb",
          handlers = {
            ["<CR>"] = function(entries, config)
              if #entries > 0 then
                vim.cmd("!git checkout " .. vim.fn.shellescape(entries[1]))
              end
            end,
            ["<C-y>"] = h.copy_to_clipboard,
          },
        },
      },
    })

    -- Additional keymaps
    vim.keymap.set("n", "<leader>fb", "<cmd>Tv buffers<cr>", { desc = "TV buffers" })
    vim.keymap.set("n", "<leader>fh", "<cmd>Tv zsh-history<cr>", { desc = "TV shell history" })
    vim.keymap.set("n", "<leader>ft", "<cmd>Tv<cr>", { desc = "TV channel selector" })
  end,
}
