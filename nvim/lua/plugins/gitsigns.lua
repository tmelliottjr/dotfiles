return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = "eol",
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- Navigation between hunks
        map("n", "]h", gs.next_hunk, "Next git hunk")
        map("n", "[h", gs.prev_hunk, "Previous git hunk")

        -- Actions
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle line blame")
        map("n", "<leader>hd", gs.diffthis, "Diff against index")

        -- Open commit on GitHub for the current line
        map("n", "<leader>hg", function()
          local remote = vim.fn.systemlist("git remote get-url origin")[1] or ""
          local repo_url = remote:gsub("%.git$", ""):gsub("git@github%.com:", "https://github.com/")
          if repo_url == "" then
            vim.notify("No GitHub remote found", vim.log.levels.WARN)
            return
          end
          local sha = vim.fn.systemlist("git blame -l -L " .. vim.fn.line(".") .. "," .. vim.fn.line(".") .. " -- " .. vim.fn.expand("%"))[1]
          if not sha then return end
          sha = sha:match("^(%x+)")
          if not sha or sha:match("^0+$") then
            vim.notify("Uncommitted change", vim.log.levels.WARN)
            return
          end
          vim.fn.system("open " .. vim.fn.shellescape(repo_url .. "/commit/" .. sha))
        end, "Open commit on GitHub")

        -- Open the PR that merged this line's commit
        map("n", "<leader>hP", function()
          local sha = vim.fn.systemlist("git blame -l -L " .. vim.fn.line(".") .. "," .. vim.fn.line(".") .. " -- " .. vim.fn.expand("%"))[1]
          if not sha then return end
          sha = sha:match("^(%x+)")
          if not sha or sha:match("^0+$") then
            vim.notify("Uncommitted change", vim.log.levels.WARN)
            return
          end
          local pr = vim.fn.systemlist("gh pr list --search " .. sha .. " --state merged --json url --jq '.[0].url'")[1]
          if pr and pr ~= "" then
            vim.fn.system("open " .. vim.fn.shellescape(pr))
          else
            vim.notify("No merged PR found for " .. sha:sub(1, 8), vim.log.levels.WARN)
          end
        end, "Open PR on GitHub")
      end,
    })
  end,
}
