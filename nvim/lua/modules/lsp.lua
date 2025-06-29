local lspconfig = require('lspconfig')

-- LSP on_attach function for keymappings
local function on_attach(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  
  -- LSP keymappings
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)         -- Go to definition
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)     -- Go to implementation
  vim.keymap.set('n', 'gu', vim.lsp.buf.references, opts)         -- Go to usage/references
  vim.keymap.set('n', 'grn', vim.lsp.buf.rename, opts)            -- Rename
  vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, opts)        -- Show all actions
  
  -- Additional helpful mappings
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)               -- Hover documentation
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)  -- Signature help
end

-- Configure diagnostics
vim.diagnostic.config({
  virtual_text = false, -- Disable virtual text, use hover instead
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'always', -- Always show the source in hover
    header = '',
    prefix = '',
    focusable = false,
    close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
  },
})

-- Setup capabilities for completion
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Language server configurations
local servers = {
  'lua_ls',
  'pyright',
  'ts_ls',
  'gopls',
  'bashls',
  'jsonls',
  'yamlls',
  'dockerls',
  'html',
  'kotlin_language_server',
  'terraformls',
  'jsonls',
}

-- Mason setup with proper handler configuration
local mason_lspconfig_ok, mason_lspconfig = pcall(require, 'mason-lspconfig')
if not mason_lspconfig_ok then
  vim.notify("mason-lspconfig not found", vim.log.levels.ERROR)
  return
end

mason_lspconfig.setup({
  ensure_installed = servers,
  automatic_enable = true, -- New setting in v2.0.0
})

-- Configure all servers with the new native vim.lsp.config API
for _, server in ipairs(servers) do
  vim.lsp.config(server, {
    capabilities = capabilities,
    on_attach = on_attach,
  })
end

-- Sign column symbols
local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
