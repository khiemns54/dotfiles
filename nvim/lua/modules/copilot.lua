require('copilot').setup({
  panel = {
    enabled = true,
    auto_refresh = true,
    keymap = {
      jump_prev = "<C-p>",
      jump_next = "C-n",
      accept = "<CR>",
    },
    layout = {
      position = "bottom", -- | top | left | right
      ratio = 0.4
    },
  },
  suggestion = {
    enabled = true,
    auto_trigger = true,
    debounce = 75,
    keymap = {
      accept = "<M-l>",
      accept_word = false,
      accept_line = false,
      next = "<C-j>",
      prev = "<C-k>",
      dismiss = "<C-]>",
    },
  },
  filetypes = {
    yaml = false,
    markdown = false,
    help = false,
    gitcommit = false,
    gitrebase = false,
    hgcommit = false,
    svn = false,
    cvs = false,
    ["."] = false,
  },
  copilot_node_command = 'node', -- Node.js version must be > 16.x
  server_opts_overrides = {},
})

-- Custom keybindings for Copilot
vim.keymap.set('n', '<leader>cp', '<cmd>Copilot panel<CR>', { desc = 'Open Copilot panel' })
vim.keymap.set('n', '<leader>cs', '<cmd>Copilot status<CR>', { desc = 'Copilot status' })
vim.keymap.set('n', '<leader>ce', '<cmd>Copilot enable<CR>', { desc = 'Enable Copilot' })
vim.keymap.set('n', '<leader>cd', '<cmd>Copilot disable<CR>', { desc = 'Disable Copilot' })

-- Show Copilot status in command line
vim.api.nvim_create_user_command('CopilotStatus', function()
  local status = require('copilot.api').status.data.status
  if status == 'Normal' then
    print('Copilot: Ready ✓')
  elseif status == 'InProgress' then
    print('Copilot: Loading...')
  else
    print('Copilot: ' .. status)
  end
end, {})

-- Set custom highlight for Copilot suggestions
vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {fg ="#6CC644"})

-- Auto-authentication check
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      local status = require('copilot.api').status.data.status
      if status == 'NotSignedIn' then
        vim.notify('Copilot: Please run :Copilot auth to authenticate', vim.log.levels.WARN)
      end
    end, 1000)
  end,
}) 
