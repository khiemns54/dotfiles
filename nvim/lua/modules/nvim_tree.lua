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


vim.keymap.set("n", "<leader>t", "<esc>:NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>f", "<esc>:NvimTreeFindFile<CR>", { noremap = true, silent = true })
