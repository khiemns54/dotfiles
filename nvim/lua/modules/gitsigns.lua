require('gitsigns').setup({
  signs = {
    add          = { text = '▎' },
    change       = { text = '▎' },
    delete       = { text = '▁' },
    topdelete    = { text = '▔' },
    changedelete = { text = '▎' },
    untracked    = { text = '▎' },
  },
  signcolumn = true,  -- Always show signs
  numhl      = false,
  linehl     = false,
  word_diff  = false,
  watch_gitdir = {
    follow_files = true
  },
  attach_to_untracked = false,
  current_line_blame = false,
  sign_priority = 6,
  update_debounce = 300,
  max_file_length = 10000,
})

-- GitBlame function as alias for 'Gitsigns blame'
function GitBlame()
  require('gitsigns').blame()
end

-- Make it available as a command
vim.api.nvim_create_user_command('GitBlame', GitBlame, {}) 