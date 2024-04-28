require("toggleterm").setup {
  size = function(term)
    if term.direction == "horizontal" then
      return 15
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.45
    end
  end,
  open_mapping = [[<c-t>]],
  hide_numbers = true,
  direction = 'vertical',
  persist_size = true,
  start_in_insert = true,
}

vimp.nnoremap("<leader>c", "<cmd>ToggleTerm<CR>")
vimp.nnoremap("<leader>C", "<cmd>ToggleTerm direction=horizontal<CR>")
