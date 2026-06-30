-- LSP on_attach function for keymappings
local function on_attach(client, bufnr)
  local filetype = vim.bo[bufnr].filetype
  if vim.bo[bufnr].buftype == 'terminal' or filetype == 'opencode_terminal' then
    vim.schedule(function()
      vim.lsp.buf_detach_client(bufnr, client.id)
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.diagnostic.reset(nil, bufnr)
      end
    end)
    return
  end

  local opts = { noremap = true, silent = true, buffer = bufnr }
  
  -- LSP keymappings
  vim.keymap.set('n', 'gd', require('telescope.builtin').lsp_definitions, opts)         -- Go to definition
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)     -- Go to implementation
  vim.keymap.set('n', 'gu', require('telescope.builtin').lsp_references, { noremap = true, silent = true })

  vim.keymap.set('n', 'grn', vim.lsp.buf.rename, opts)            -- Rename
  vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, opts)        -- Show all actions
  
  -- Additional helpful mappings
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)               -- Hover documentation
  vim.keymap.set('n', '<leader>k', vim.lsp.buf.signature_help, opts)  -- Signature help
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
  'terraformls',
}

-- Mason setup with proper handler configuration
local mason_lspconfig_ok, mason_lspconfig = pcall(require, 'mason-lspconfig')
if not mason_lspconfig_ok then
  vim.notify("mason-lspconfig not found", vim.log.levels.ERROR)
  return
end

-- Configure all servers with the new native vim.lsp.config API
for _, server in ipairs(servers) do
  vim.lsp.config(server, {
    capabilities = capabilities,
    on_attach = on_attach,
  })
end

local kotlin_root_markers = {
  { 'settings.gradle', 'settings.gradle.kts', 'pom.xml', 'workspace.json' },
  { 'build.gradle', 'build.gradle.kts' },
}
local kotlin_root_marker_files = {
  'settings.gradle', 'settings.gradle.kts', 'pom.xml', 'workspace.json',
  'build.gradle', 'build.gradle.kts',
}

local kotlin_lsp_config = {
  cmd = { vim.fn.expand('~/.local/share/kotlin-lsp/bin/intellij-server'), '--stdio' },
  cmd_env = {
    IJ_JAVA_OPTIONS = '-Djdk.lang.Process.launchMechanism=FORK',
    JAVA_HOME = '/Users/khiemns/Library/Java/JavaVirtualMachines/ms-21.0.8/Contents/Home',
  },
  capabilities = capabilities,
  on_attach = on_attach,
  root_markers = kotlin_root_markers,
  settings = {
    intellij = {
      jdkForSymbolResolution = '/Users/khiemns/Library/Java/JavaVirtualMachines/ms-21.0.8/Contents/Home',
    },
  },
  single_file_support = false,
}

vim.lsp.config('kotlin_lsp', kotlin_lsp_config)
vim.lsp.enable('kotlin_lsp')

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(args)
    if vim.bo[args.buf].buftype == 'terminal' or vim.bo[args.buf].filetype == 'opencode_terminal' then
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
        vim.lsp.buf_detach_client(args.buf, client.id)
      end
      vim.diagnostic.reset(nil, args.buf)
      return
    end

    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == '' then
      return
    end

    local root = vim.fs.root(args.buf, kotlin_root_marker_files)
    if not root then
      return
    end

    vim.lsp.start(vim.tbl_extend('force', kotlin_lsp_config, {
      name = 'kotlin_lsp',
      root_dir = root,
    }), {
      bufnr = args.buf,
      reuse_client = function(client, config)
        return client.name == config.name and client.config.root_dir == config.root_dir
      end,
    })
  end,
})

mason_lspconfig.setup({
  ensure_installed = servers,
  automatic_enable = servers,
})

-- Sign column symbols
local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
