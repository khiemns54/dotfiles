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
  direction = 'horizontal',
  persist_size = true,
  start_in_insert = true,
}

vim.keymap.set("n", "<leader>c", "<cmd>ToggleTerm direction=horizontal<CR>", { noremap = true, silent = true, desc = "Toggle terminal" })