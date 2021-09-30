local vimp = require("vimp")

vim.g.mapleader = "s"
vimp.nnoremap("<leader><leader>", "o<ESC>")
vimp.nnoremap("<leader>a", "mi=ip`i<CR>")
vimp.nnoremap("<leader>w", ":w<CR>")
vimp.inoremap("<C-j>",  "<down>")
vimp.inoremap("<C-k>",  "<up>")
vimp.inoremap("<C-h>",  "<left>")
vimp.inoremap("<C-l>",  "<right>")
vimp.nnoremap("<Tab>",   ">>")
vimp.nnoremap("<S-Tab>", "<<")
vimp.nnoremap("<Space>", "i<Space><ESC>l")
vimp.tnoremap("<C-n>", "<C-\\><C-n>")
vimp.tnoremap("<C-w>h", "<C-\\><C-n><C-w>h")
vimp.tnoremap("<C-w>j", "<C-\\><C-n><C-w>j")
vimp.tnoremap("<C-w>k", "<C-\\><C-n><C-w>k")
vimp.tnoremap("<C-w>l", "<C-\\><C-n><C-w>l")
vim.cmd [[ nnoremap s <NOP> ]]
