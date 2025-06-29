-- Global configs
CONFIG_PATH = vim.fn.stdpath("config")
DATA_PATH   = vim.fn.stdpath("data")
CACHE_PATH  = vim.fn.stdpath("cache")

PACKER_INSTALL_PATH  = DATA_PATH .. "/site/pack/packer/opt/packer.nvim"
PACKER_COMPILED_PATH = DATA_PATH .. "/site/plugin/packer_compiled.vim"
--

local cmd = vim.cmd
local opt = vim.opt
cmd [[
  filetype plugin on
  augroup do
    autocmd!
    autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=4 shiftwidth=4
    autocmd BufNewFile,BufRead *.java setlocal noexpandtab tabstop=4 shiftwidth=4
    autocmd BufNewFile,BufRead *.class setlocal noexpandtab tabstop=4 shiftwidth=4
  augroup END
  au FileType javascript,typescript setlocal cindent indentexpr&
  au BufWinEnter *.<fileextension> set updatetime=300 | set ft=<filetype>| set autoread
  au CursorHold *.<fileextension>  checktime
]]

vim.g.mapleader = "s"
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.shortmess:append "c"
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.showmode = false
opt.fileencoding = "utf-8"
opt.mouse = "a"
opt.lazyredraw = true
opt.updatetime = 250
opt.timeoutlen = 500
opt.signcolumn = "yes"
opt.autowrite = true
opt.autoread = true
opt.hidden = true
opt.hlsearch = true
opt.cursorline = true
opt.scrolloff = 999
opt.ignorecase = true
opt.smartcase = true
opt.number = true
opt.relativenumber = false
opt.completeopt = { 'menuone', 'noselect' }
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shadafile = "NONE"
opt.title = true
opt.foldlevelstart = 99
opt.so = 1
opt.completeopt = {'menu', 'menuone', 'noselect'} -- Disable completion to nvim-cmp

-- Error handling and debugging
opt.verbose = 0                  -- Enable verbose output for debugging
opt.debug = ''              -- Throw errors with full stack traces
vim.g.debug = false               -- Enable debug mode

-- Debug toggle function
local function toggle_debug()
  if vim.g.debug then
    -- Turn off debug mode
    vim.g.debug = false
    vim.opt.verbose = 0
    vim.opt.debug = ''
    print("Debug mode: OFF")
  else
    -- Turn on debug mode
    vim.g.debug = true
    vim.opt.verbose = 1
    vim.opt.debug = 'throw'
    print("Debug mode: ON")
  end
end

-- Create user command for debug toggle
vim.api.nvim_create_user_command('Debug', toggle_debug, {
  desc = 'Toggle debug mode and error stack traces'
})

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔄 CONFIGURATION RELOAD COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- Commands for reloading Neovim configuration without restarting

-- Complete reload: config + plugins clean/sync
vim.api.nvim_create_user_command('ReloadAll', function()
  require('utils').reload_all()
end, {
  desc = 'Reload all Neovim configuration and reinstall plugins'
})
