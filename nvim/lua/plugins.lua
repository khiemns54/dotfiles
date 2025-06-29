local packer = require'packer_init'

vim.cmd[[packadd packer.nvim]]

require("packer").startup(function()
  use {'wbthomason/packer.nvim', opt = true}

  use {
    'svermeulen/vimpeccable',
    config = function()
      require'vimp'.always_override = true
    end
  } 

  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} },
    setup = [[require'modules/telescope'.setup()]],
    config = [[require'modules/telescope'.config()]],
  }

  use {'nvim-telescope/telescope-ui-select.nvim' }

  -- Common
  use {
    "talek/obvious-resize",
    config = function()
      vim.cmd [[
      let g:obvious_resize_default = 10
      nnoremap <silent> <C-K> :<C-U>ObviousResizeUp<CR>
      nnoremap <silent> <C-J> :<C-U>ObviousResizeDown<CR>
      nnoremap <silent> <C-H> :<C-U>ObviousResizeLeft<CR>
      nnoremap <silent> <C-L> :<C-U>ObviousResizeRight<CR>
      ]]
    end
  }

  -- File manager
  use {
    'kyazdani42/nvim-tree.lua',
    disable = true,
    requires = 'kyazdani42/nvim-web-devicons',
    config = [[require'modules/nvim_tree']]
  }

  use {
    'preservim/nerdtree',
    disable = false,
    requires = 'ryanoasis/vim-devicons',
    config = function()
      vim.cmd[[
        nnoremap <silent> <Leader>f :NERDTreeFind<CR>
        let NERDTreeQuitOnOpen=1
      ]]
    end
  }

  -- UI
  use {
    "ellisonleao/gruvbox.nvim",
    config = function()
      vim.cmd("colorscheme gruvbox")
    end
  }

  use {'glepnir/dashboard-nvim'}

  -- Git Integration
  use {
    'lewis6991/gitsigns.nvim',
    -- Purpose: Git integration with sign column indicators for changes
    -- Features: show added/modified/deleted lines, stage hunks, blame, etc.
    config = [[require('modules/gitsigns')]]
  }

  -- Terminal
  use {
    "akinsho/toggleterm.nvim",
    config = [[require('modules/terminal')]],
  }

  --[[
  ═══════════════════════════════════════════════════════════════════════════════════════
  📋 LSP & CODE INTELLIGENCE ECOSYSTEM
  ═══════════════════════════════════════════════════════════════════════════════════════
  
  This section contains all Language Server Protocol (LSP) related plugins that provide:
  - Intelligent code navigation, completion, and analysis
  - Real-time diagnostics and error checking  
  - Code formatting, refactoring, and quick fixes
  - AI-powered code suggestions via GitHub Copilot
  - Enhanced development experience with signatures and status
  
  🔧 Key Commands & Shortcuts:
  • :Mason - Open LSP server installer/manager
  • :LspInfo - Show active LSP client information
  • :CopilotStatus - Check GitHub Copilot authentication status
  • :Copilot auth - Authenticate with GitHub Copilot
  
  📋 Navigation & Actions (configured in modules/lsp.lua):
  • gd - Go to definition            • gr - Go to references
  • gD - Go to declaration           • gi - Go to implementation  
  • K - Show hover documentation     • <space>rn - Rename symbol
  • <space>ca - Code actions         • <space>f - Format document
  • <C-k> - Signature help           • <space>D - Type definition
  
  🩺 Diagnostics:
  • <space>e - Show line diagnostics • [d/]d - Previous/next diagnostic
  • <space>q - Open diagnostics list
  
  ⚡ Completion (Ctrl+Space to trigger):
  • <Tab>/<S-Tab> - Navigate items   • <C-j>/<C-k> - Next/previous item
  • <CR> - Confirm selection         • <C-e> - Close completion menu
  • <C-b>/<C-f> - Scroll docs up/down
  
  🤖 GitHub Copilot:
  • <M-l> - Accept suggestion        • <M-]>/<M-[> - Next/previous suggestion
  • <C-]> - Dismiss suggestion       • <leader>cp - Open Copilot panel
  • <leader>cs - Copilot status      • <leader>ce/<leader>cd - Enable/disable
  ]]

  -- 🔧 LSP Server Management
  use {
    'williamboman/mason.nvim',
    -- Purpose: Package manager for LSP servers, DAP servers, linters, and formatters
    -- Provides a UI to easily install and manage language tools
    config = function()
      require('mason').setup()
    end
  }

  use {
    'williamboman/mason-lspconfig.nvim',
    -- Purpose: Bridge between mason.nvim and lspconfig
    -- Automatically installs LSP servers and integrates with lspconfig setup
    after = 'mason.nvim',
  }

  -- 🧠 Core LSP Functionality  
  use {
    'neovim/nvim-lspconfig',
    -- Purpose: Official configurations for Neovim's built-in LSP client
    -- Provides pre-configured setups for 200+ language servers
    -- Enables: go-to-definition, hover docs, diagnostics, formatting, etc.
    after = 'mason-lspconfig.nvim',
    config = [[require('modules/lsp')]]
  }

  -- ⚡ Intelligent Code Completion
  use {
    'hrsh7th/nvim-cmp',
    -- Purpose: Completion engine with multiple sources support
    -- Features: snippet expansion, fuzzy matching, customizable UI
    requires = {
      'hrsh7th/cmp-nvim-lsp',     -- LSP completion source
      'hrsh7th/cmp-buffer',       -- Buffer text completion
      'hrsh7th/cmp-path',         -- File path completion (update with :PackerSync to fix vim.validate deprecation)
      'hrsh7th/cmp-cmdline',      -- Command line completion
      'L3MON4D3/LuaSnip',         -- Snippet engine
      'saadparwaiz1/cmp_luasnip', -- Snippet completion source
    },
    config = [[require('modules/cmp')]]
  }

  -- 🤖 AI-Powered Code Assistant
  use {
    'zbirenbaum/copilot.lua',
    -- Purpose: GitHub Copilot integration for AI code suggestions
    -- Features: context-aware completions, inline suggestions, chat interface
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function ()
      require('copilot').setup({
        suggestion = { enabled = false },
        panel = { enabled = false }
      })
    end
  }

  use {
    'zbirenbaum/copilot-cmp',
    -- Purpose: Integrates GitHub Copilot suggestions into nvim-cmp
    -- Allows Copilot suggestions to appear alongside other completion sources
    after = { 'copilot.lua' },
    config = function()
      require('copilot_cmp').setup()
    end
  }

  -- 📝 Enhanced LSP Experience
  use {
    'ray-x/lsp_signature.nvim',
    -- Purpose: Show function signatures while typing
    -- Features: parameter highlighting, floating window with docs
    config = [[require('modules/lspsignature')]]
  }

  -- Removed lsp-status.nvim - replaced with custom implementation in lualine.lua

  -- 📊 Enhanced Status Line with LSP Integration
  use {
    'nvim-lualine/lualine.nvim',
    -- Purpose: Fast and configurable statusline with LSP information
    -- Features: shows active LSP servers, diagnostics, progress, current function
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = [[require('modules/lualine')]]
  }

  -- Treesitter for better syntax highlighting
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = [[require('modules/treesitter')]]
  }
end)

vim.g.dashboard_default_executive = 'telescope'

