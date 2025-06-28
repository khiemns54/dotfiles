-- Custom LSP progress tracking (replaces lsp-status.nvim)
local lsp_progress = {}

-- Track LSP progress messages
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(args)
    local client_id = args.data.client_id
    local result = args.data.result
    
    if not result then return end
    
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then return end
    
    lsp_progress[client_id] = lsp_progress[client_id] or {}
    
    if result.kind == 'begin' then
      lsp_progress[client_id][result.token] = {
        title = result.title,
        message = result.message,
        percentage = result.percentage
      }
    elseif result.kind == 'report' then
      local progress = lsp_progress[client_id][result.token]
      if progress then
        progress.message = result.message or progress.message
        progress.percentage = result.percentage or progress.percentage
      end
    elseif result.kind == 'end' then
      if lsp_progress[client_id] then
        lsp_progress[client_id][result.token] = nil
      end
    end
  end,
})

-- Function to get current LSP status
local function get_lsp_progress()
  local messages = {}
  
  for client_id, client_progress in pairs(lsp_progress) do
    local client = vim.lsp.get_client_by_id(client_id)
    if client then
      for token, progress in pairs(client_progress) do
        local msg = progress.title
        if progress.message then
          msg = msg .. ': ' .. progress.message
        end
        if progress.percentage then
          msg = msg .. ' (' .. progress.percentage .. '%)'
        end
        table.insert(messages, msg)
      end
    end
  end
  
  if #messages > 0 then
    return '⏳ ' .. table.concat(messages, ', ')
  end
  
  -- Show diagnostic counts when no progress
  local diagnostics = vim.diagnostic.get(0)
  local counts = { errors = 0, warnings = 0, info = 0, hints = 0 }
  
  for _, diagnostic in ipairs(diagnostics) do
    local severity = diagnostic.severity
    if severity == vim.diagnostic.severity.ERROR then
      counts.errors = counts.errors + 1
    elseif severity == vim.diagnostic.severity.WARN then
      counts.warnings = counts.warnings + 1
    elseif severity == vim.diagnostic.severity.INFO then
      counts.info = counts.info + 1
    elseif severity == vim.diagnostic.severity.HINT then
      counts.hints = counts.hints + 1
    end
  end
  
  local status_parts = {}
  if counts.errors > 0 then
    table.insert(status_parts, ' ' .. counts.errors)
  end
  if counts.warnings > 0 then
    table.insert(status_parts, ' ' .. counts.warnings)
  end
  if counts.info > 0 then
    table.insert(status_parts, ' ' .. counts.info)
  end
  if counts.hints > 0 then
    table.insert(status_parts, ' ' .. counts.hints)
  end
  
  return #status_parts > 0 and table.concat(status_parts, ' ') or ' '
end

require('lualine').setup({
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = true,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      {
        -- LSP server names
        function()
          local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
          if next(clients) == nil then
            return 'No LSP'
          end
          
          local client_names = {}
          for _, client in pairs(clients) do
            table.insert(client_names, client.name)
          end
          
          return '󰒋 ' .. table.concat(client_names, ', ')
        end,
        color = { fg = '#98be65' },
      }
    },
    lualine_x = {
      {
        -- LSP status and progress (custom implementation)
        get_lsp_progress,
        color = { fg = '#ffcc66' },
      }
    },
    lualine_y = {},
    lualine_z = {}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
})

-- No longer using lsp-status.nvim - custom implementation above