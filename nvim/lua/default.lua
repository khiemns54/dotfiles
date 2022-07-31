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
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
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
