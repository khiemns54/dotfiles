
-- Migrated from Packer.nvim

return {
  -- Telescope - Fuzzy Finder
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    },
    init = function()
      require'modules/telescope'.setup()
    end,
    config = function()
      require'modules/telescope'.config()
    end,
  },

  -- Inline images (Kitty graphics protocol) for Markdown
  {
    '3rd/image.nvim',
    ft = { 'markdown' },
    opts = {
      backend = 'kitty',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = false,
          only_render_image_at_cursor = false,
        },
      },
      max_width = 80,
      max_height = 40,
      max_width_window_percentage = 50,
      window_overlap_clear_enabled = true,
      editor_only_render_when_focused = true,
    },
  },

  -- PlantUML syntax (for fenced code blocks and .puml files)
  {
    'aklt/plantuml-syntax',
    ft = { 'plantuml', 'uml', 'markdown' },
  },

  {
    'nvim-telescope/telescope-ui-select.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
  },

  -- Window resize
  {
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
  },

  -- File manager - nvim-tree (disabled)
  {
    'kyazdani42/nvim-tree.lua',
    enabled = false,
    dependencies = 'kyazdani42/nvim-web-devicons',
    config = function()
      require'modules/nvim_tree'
    end
  },

  -- File manager - NERDTree
  {
    'preservim/nerdtree',
    dependencies = 'ryanoasis/vim-devicons',
    cmd = { "NERDTree", "NERDTreeFind", "NERDTreeToggle" },
    keys = {
      { "<Leader>f", "<cmd>NERDTreeFind<CR>", desc = "Find in NERDTree", silent = true },
    },
    config = function()
      vim.cmd[[
        nnoremap <silent> <Leader>f :NERDTreeFind<CR>
        let NERDTreeQuitOnOpen=1
      ]]
    end
  },

  -- UI - Colorscheme
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd("colorscheme gruvbox")
    end
  },

  -- Dashboard
  {
    'glepnir/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      vim.g.dashboard_default_executive = 'telescope'
    end
  },

  -- Git Integration
  {
    'lewis6991/gitsigns.nvim',
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require('modules/gitsigns')
    end
  },

  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { "<Leader>c", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
    },
    config = function()
      require('modules/terminal')
    end,
  },

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
  {
    'williamboman/mason.nvim',
    cmd = { "Mason", "MasonInstall", "MasonUninstall" },
    config = function()
      require('mason').setup()
    end
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    event = { "BufReadPre", "BufNewFile" },
  },

  -- 🧠 Core LSP Functionality  
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'williamboman/mason-lspconfig.nvim' },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require('modules/lsp')
    end
  },

  -- ⚡ Intelligent Code Completion
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',     -- LSP completion source
      'hrsh7th/cmp-buffer',       -- Buffer text completion
      'hrsh7th/cmp-path',         -- File path completion
      'hrsh7th/cmp-cmdline',      -- Command line completion
      'L3MON4D3/LuaSnip',         -- Snippet engine
      'saadparwaiz1/cmp_luasnip', -- Snippet completion source
    },
    config = function()
      require('modules/cmp')
    end
  },

  -- 🤖 AI-Powered Code Assistant
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        suggestion = { enabled = false },
        panel = { enabled = false }
      })
    end
  },

  {
    'zbirenbaum/copilot-cmp',
    dependencies = { 'zbirenbaum/copilot.lua' },
    event = "InsertEnter",
    config = function()
      require('copilot_cmp').setup()
    end
  },

  -- 📝 Enhanced LSP Experience
  {
    'ray-x/lsp_signature.nvim',
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require('modules/lspsignature')
    end
  },

  -- 📊 Enhanced Status Line with LSP Integration
  {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require('modules/lualine')
    end
  },

  -- Treesitter for better syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    event = { "BufReadPre", "BufNewFile" },
    build = ':TSUpdate',
    config = function()
      require('modules/treesitter')
    end
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function ()
      require("ibl").setup()
    end
  },

  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    build = "make",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      "stevearc/dressing.nvim",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
    config = function()
      require('avante').setup({
        -- Use claude-code as the default provider (via ACP)
        provider = "codex",

        -- Native provider configurations (fallback option)
        --providers = {
        --  bedrock = {
        --    model = "jp.anthropic.claude-sonnet-4-5-20250929-v1:0",
        --    aws_profile = "paypay-claude-cli-sso",
        --    aws_region = "ap-northeast-1",
        --    timeout = 30000, -- Timeout in milliseconds
        --  },
        --},

        -- ACP provider configurations
        acp_providers = {
          ["codex"] = {
            command = "npx",
            args = { "@zed-industries/codex-acp" },
            env = {
              NODE_NO_WARNINGS = "1",
            },
          },
          ["claude-code"] = {
            command = "npx",
            args = { "@zed-industries/claude-code-acp" },
            env = {
              NODE_NO_WARNINGS = "1",
              -- Use Bedrock instead of direct API
              CLAUDE_CODE_USE_BEDROCK = "1",
              AWS_REGION = "ap-northeast-1",
              AWS_PROFILE = "paypay-claude-cli-sso",
              ANTHROPIC_MODEL="jp.anthropic.claude-sonnet-4-5-20250929-v1:0",
              ANTHROPIC_SMALL_MODEL="anthropic.claude-3-5-sonnet-20240620-v1:0",
              ANTHROPIC_DEFAULT_SONNET_MODEL="jp.anthropic.claude-sonnet-4-5-20250929-v1:0",
            },
          },
        },

        -- Behavior settings
        behaviour = {
          auto_suggestions = false,
          auto_set_highlight_group = true,
          auto_set_keymaps = false, -- Disable default keymaps as requested
          auto_apply_diff_after_generation = false,
          support_paste_from_clipboard = true,
          minimize_diff = true,
          enable_token_counting = true,
          auto_add_current_file = true,
          auto_approve_tool_permissions = true,
          confirmation_ui_style = "inline_buttons",
          acp_follow_agent_locations = true,
        },

        -- Project-specific instructions file
        instructions_file = "AGENTS.md",

        -- Window settings
        windows = {
          position = "right",
          wrap = true,
          width = 35,
          sidebar_header = {
            align = "center",
            rounded = true,
          },
        },

        -- Highlight settings
        highlights = {
          diff = {
            current = "DiffText",
            incoming = "DiffAdd"
          },
        },
      })
    end,
  }
}
