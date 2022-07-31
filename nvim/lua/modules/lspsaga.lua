local saga = require 'lspsaga'

saga.init_lsp_saga {
  finder_action_keys = {
    quit = 'q'
  },
  code_action_keys = {
    quit = 'q'
  },
  rename_action_keys = {
    quit = '<Esc>'
  }
}

vim.cmd [[
nnoremap <silent>gh <cmd>lua require('lspsaga.codeaction').code_action()<CR>
nnoremap <silent>gH <cmd>Lspsaga lsp_finder<CR>
nnoremap <silent> ge :Lspsaga show_line_diagnostics<CR>
nnoremap <silent>gr :Lspsaga rename<CR>
vnoremap <silent><leader>ca :<C-U>lua require('lspsaga.codeaction').range_code_action()<CR>nnoremap <silent> K <cmd>lua require('lspsaga.hover').render_hover_doc()<CR>
]]
