-- Editor defaults (not a plugin, but lazy.nvim allows non-plugin specs)
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- Auto-switch to absolute line numbers in Insert mode, relative in Normal
local number_toggle = vim.api.nvim_create_augroup("NumberToggle", { clear = true })
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
  group = number_toggle,
  callback = function() vim.opt.relativenumber = false end,
})
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  group = number_toggle,
  callback = function() vim.opt.relativenumber = true end,
})

-- Toggle word wrap
vim.keymap.set("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify("Wrap " .. (vim.wo.wrap and "on" or "off"))
end, { desc = "Toggle word wrap" })

-- Auto-enable wrap for prose files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end,
})

-- Auto-save when leaving insert mode, switching buffers, or losing focus
vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "FocusLost" }, {
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.fn.bufname(buf) ~= "" then
      vim.api.nvim_buf_call(buf, function() vim.cmd("silent! write") end)
    end
  end,
})

return {}
