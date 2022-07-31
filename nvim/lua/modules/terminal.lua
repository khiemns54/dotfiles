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
}

vimp.nnoremap("<leader>c", "<cmd>ToggleTerm<CR>")
vimp.nnoremap("<leader>C", "<cmd>ToggleTerm direction=horizontal<CR>")

local Terminal  = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({
  cmd = "lazygit",
  dir = "git_dir",
  direction = "float",
  float_opts = {
    border = "double",
  },
  -- function to run on opening the terminal
  on_open = function(term)
    vim.cmd("startinsert!")
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
  end,
  -- function to run on closing the terminal
  on_close = function(term)
    vim.cmd("quit")
  end,
})

local lazydocker = Terminal:new({
  cmd = "lazydocker",
  direction = "float",
  float_opts = {
    border = "double",
  },
  -- function to run on opening the terminal
  on_open = function(term)
    vim.cmd("startinsert!")
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
  end,
  -- function to run on closing the terminal
  on_close = function(term)
    vim.cmd("quit")
  end,
})

function _lazygit_toggle()
  lazygit:toggle()
end

function _docker_toggle()
  lazydocker:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>G", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<leader>D", "<cmd>lua _docker_toggle()<CR>", {noremap = true, silent = true})
