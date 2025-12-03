-- Global configs
CONFIG_PATH = vim.fn.stdpath("config")
DATA_PATH   = vim.fn.stdpath("data")
CACHE_PATH  = vim.fn.stdpath("cache")

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
opt.autowriteall = true  -- Auto-save on buffer switch, like IntelliJ
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


-- Default keybindings
vim.g.mapleader = "s"
-- Normal mode
vim.keymap.set("n", "<leader><leader>", "o<ESC>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>a", "mi=ip`i<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Space>", "i<Space><ESC>l", { noremap = true, silent = true })

-- Terminal mode
vim.keymap.set("t", "<C-n>", "<C-\\><C-n>", { noremap = true, silent = true })
vim.keymap.set("t", "<C-w>h", "<C-\\><C-n><C-w>h", { noremap = true, silent = true })
vim.keymap.set("t", "<C-w>j", "<C-\\><C-n><C-w>j", { noremap = true, silent = true })
vim.keymap.set("t", "<C-w>k", "<C-\\><C-n><C-w>k", { noremap = true, silent = true })
vim.keymap.set("t", "<C-w>l", "<C-\\><C-n><C-w>l", { noremap = true, silent = true })

-- Command-line mode
vim.keymap.set("c", "<C-j>", "<C-n>", { noremap = true })
vim.keymap.set("c", "<C-k>", "<C-p>", { noremap = true })

-- Disable 's' in normal mode
vim.keymap.set("n", "s", "<NOP>", { noremap = true })

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 💾 AUTO-SAVE & AUTO-RELOAD (IntelliJ-like behavior)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- Auto-save group
vim.api.nvim_create_augroup('AutoSave', { clear = true })

-- Auto-save on focus lost, buffer leave, and cursor hold
vim.api.nvim_create_autocmd({'FocusLost', 'BufLeave', 'CursorHold'}, {
  group = 'AutoSave',
  pattern = '*',
  callback = function()
    -- Only save if buffer is modifiable, modified, and has a filename
    if vim.bo.modifiable and vim.bo.modified and vim.fn.expand('%') ~= '' then
      pcall(function()
        vim.cmd('silent! write')
      end)
    end
  end,
  desc = 'Auto-save buffer on focus lost, buffer leave, or cursor hold'
})

-- Auto-reload group with conflict detection
vim.api.nvim_create_augroup('AutoReload', { clear = true })

-- Check for external changes when entering buffer or gaining focus
vim.api.nvim_create_autocmd({'FocusGained', 'BufEnter', 'CursorHold'}, {
  group = 'AutoReload',
  pattern = '*',
  callback = function()
    -- Only check if buffer has a filename
    if vim.fn.expand('%') ~= '' then
      pcall(function()
        -- Check if file has changed on disk
        vim.cmd('checktime')
      end)
    end
  end,
  desc = 'Auto-reload buffer when file changes externally'
})

-- Handle file change notification with conflict detection
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = 'AutoReload',
  pattern = '*',
  callback = function()
    vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.WARN)
  end,
  desc = 'Notify when file is reloaded due to external changes'
})

-- Warn before reloading if there are unsaved changes (conflict detection)
vim.api.nvim_create_autocmd('FileChangedShell', {
  group = 'AutoReload',
  pattern = '*',
  callback = function()
    if vim.bo.modified then
      -- File has unsaved changes and external changes - prompt user
      vim.notify('Warning: File has changed on disk and you have unsaved changes!', vim.log.levels.ERROR)
      local choice = vim.fn.confirm(
        'File has changed on disk. Current buffer has unsaved changes.\n' ..
        'What do you want to do?',
        '&Load File\n&Keep Buffer\n&Diff',
        2
      )

      if choice == 1 then
        -- Load file from disk (discard buffer changes)
        vim.cmd('edit!')
        vim.notify('Buffer reloaded from disk. Your changes were discarded.', vim.log.levels.WARN)
      elseif choice == 2 then
        -- Keep buffer changes
        vim.notify('Keeping buffer changes. File on disk was not loaded.', vim.log.levels.INFO)
      elseif choice == 3 then
        -- Show diff
        vim.cmd('DiffOrig')
        vim.notify('Showing diff. Use :diffoff to exit diff mode.', vim.log.levels.INFO)
      end

      return true  -- Prevent default behavior
    end
  end,
  desc = 'Confirm action when file changes externally and buffer is modified'
})

-- Create DiffOrig command to show diff between buffer and file on disk
vim.api.nvim_create_user_command('DiffOrig', function()
  local filetype = vim.bo.filetype
  vim.cmd('vertical new')
  vim.cmd('set buftype=nofile')
  vim.cmd('read ++edit #')
  vim.cmd('0d_')
  vim.cmd('diffthis')
  vim.cmd('wincmd p')
  vim.cmd('diffthis')
  if filetype ~= '' then
    vim.cmd('set filetype=' .. filetype)
  end
end, {
  desc = 'Show diff between current buffer and file on disk'
})
