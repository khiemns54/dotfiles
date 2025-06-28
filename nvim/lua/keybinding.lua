local vimp = require("vimp")

vim.g.mapleader = "s"
vimp.nnoremap("<leader><leader>", "o<ESC>")
vimp.nnoremap("<leader>a", "mi=ip`i<CR>")
vimp.nnoremap("<Space>", "i<Space><ESC>l")
vimp.tnoremap("<C-n>", "<C-\\><C-n>")
vimp.tnoremap("<C-w>h", "<C-\\><C-n><C-w>h")
vimp.tnoremap("<C-w>j", "<C-\\><C-n><C-w>j")
vimp.tnoremap("<C-w>k", "<C-\\><C-n><C-w>k")
vimp.tnoremap("<C-w>l", "<C-\\><C-n><C-w>l")

-- Command-line mode navigation
vimp.cnoremap("<C-j>", "<C-n>")
vimp.cnoremap("<C-k>", "<C-p>")

vim.cmd [[ nnoremap s <NOP> ]]
