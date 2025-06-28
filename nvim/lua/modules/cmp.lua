local cmp = require('cmp')
local luasnip = require('luasnip')

-- Load snippets from friendly-snippets
require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  
  -- Sources prioritized: copilot > lsp > buffer
  sources = cmp.config.sources({
    { name = 'copilot', priority = 1000 },
    { name = 'nvim_lsp', priority = 900 },
    { name = 'buffer', priority = 800 },
    { name = 'path', priority = 700 },
  }),
  
  formatting = {
    format = function(entry, vim_item)
      -- Kind icons
      local kind_icons = {
        Text = "",
        Method = "󰆧",
        Function = "󰊕",
        Constructor = "",
        Field = "󰇽",
        Variable = "󰂡",
        Class = "󰠱",
        Interface = "",
        Module = "",
        Property = "󰜢",
        Unit = "",
        Value = "󰎠",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "",
        Color = "󰏘",
        File = "󰈙",
        Reference = "",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰏿",
        Struct = "",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "󰅲",
        Copilot = "",
      }
      
      vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
      
      -- Source labels
      vim_item.menu = ({
        copilot = "[Copilot]",
        nvim_lsp = "[LSP]",
        buffer = "[Buffer]",
        path = "[Path]",
      })[entry.source.name]
      
      return vim_item
    end
  },
})
