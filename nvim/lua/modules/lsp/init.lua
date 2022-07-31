local lsp = require'lspconfig'
local util = require 'lspconfig/util'

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'ge', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)

end

lsp.jdtls.setup{
  on_attach = on_attach,
  cmd = {DATA_PATH .. "/lspinstall/java/jdtls.sh"},
  filetypes = { "java" },
  root_dir = require('lspconfig/util').root_pattern({'.git', 'build.gradle', 'pom.xml'}),
}


lsp.tsserver.setup {
  cmd = {DATA_PATH .. "/lspinstall/typescript/node_modules/.bin/typescript-language-server", "--stdio"},
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  on_attach = on_attach,
  root_dir = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
  settings = {documentFormatting = false},
}


lsp.kotlin_language_server.setup {
  cmd = {DATA_PATH .. "/lspinstall/kotlin/server/bin/kotlin-language-server"},
  filetypes = { "kotlin" },
  on_attach = on_attach,
  root_dir = util.root_pattern("settings.gradle.kts"),
}

