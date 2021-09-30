local vimp = require'vimp'

vim.g.nvim_tree_ignore = {
  '.git',
  'node_modules',
  '.cache',
  ".DS_Store",
  "tmp",
  ".node_modules",

}
vim.g.nvim_tree_gitignore = 1

require'nvim-tree'.setup {
  view = {
    width = 50,
    auto_resize = true,
  }
}

vimp.nnoremap("<leader>t", "<esc>:NvimTreeToggle<CR>")
vimp.nnoremap("<leader>f", "<esc>:NvimTreeFindFile<CR>")
