-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key before lazy (recommended by lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Setup lazy.nvim with plugin specs from lua/plugins/
require("lazy").setup("plugins")
