
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

  -- Auto-resize focused window (golden ratio)
  -- Only visible with multiple editor splits (e.g. :vs), not with edge panels.
  {
    "nvim-focus/focus.nvim",
    version = false,
    lazy = false,
    config = function()
      require("focus").setup({
        autoresize = {
          enable = true,
          minwidth = 10,
          minheight = 5,
        },
        ui = {
          cursorline = false,
          signcolumn = false,
        },
      })

      -- Disable focus autoresize for edgy-managed filetypes so they
      -- stay at the size edgy.nvim assigns them.
      local ignore_filetypes = { "nerdtree", "toggleterm", "opencode_terminal", "qf", "dashboard" }
      local ignore_buftypes = { "nofile", "prompt", "popup", "terminal" }

      local augroup = vim.api.nvim_create_augroup("FocusDisable", { clear = true })
      vim.api.nvim_create_autocmd("WinEnter", {
        group = augroup,
        callback = function()
          if vim.tbl_contains(ignore_buftypes, vim.bo.buftype) then
            vim.w.focus_disable = true
          end
        end,
        desc = "Disable focus autoresize for BufType",
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        callback = function()
          if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
            vim.b.focus_disable = true
          end
        end,
        desc = "Disable focus autoresize for FileType",
      })
    end,
  },

  -- Layout manager - fixed IDE-like pane positions
  -- Left: NERDTree | Center: Editor | Bottom: Terminal | Right: OpenCode
  -- Focused panel grows, unfocused shrinks back to default via edgy_width/edgy_height.
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = "screen"
    end,
    config = function(_, opts)
      require("edgy").setup(opts)

      -- Panel focus-resize: when entering an edge panel, grow it;
      -- when leaving, shrink it back to default size.
      -- Uses edgy's own edgy_width/edgy_height window vars so the
      -- layout system handles the actual resize consistently.
      local Layout = require("edgy.layout")

      -- Focused sizes for each panel (unfocused = the `size` in opts below)
      local focused_sizes = {
        nerdtree         = { width = 45 },
        toggleterm       = { height = 0.5 },
        opencode_terminal = { width = 0.55 },
      }

      local panel_filetypes = {}
      for ft, _ in pairs(focused_sizes) do
        panel_filetypes[ft] = true
      end

      local resize_group = vim.api.nvim_create_augroup("EdgePanelResize", { clear = true })

      vim.api.nvim_create_autocmd("WinEnter", {
        group = resize_group,
        callback = function()
          vim.schedule(function()
            local win = vim.api.nvim_get_current_win()
            if not vim.api.nvim_win_is_valid(win) then return end
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype

            if panel_filetypes[ft] then
              -- Grow this panel to focused size
              local sizes = focused_sizes[ft]
              if sizes.width then
                local w = sizes.width
                if w < 1 then w = math.floor(vim.o.columns * w) end
                vim.w[win].edgy_width = w
              end
              if sizes.height then
                local h = sizes.height
                if h < 1 then h = math.floor(vim.o.lines * h) end
                vim.w[win].edgy_height = h
              end
              Layout.update()
            end
          end)
        end,
        desc = "Grow focused edge panel",
      })

      vim.api.nvim_create_autocmd("WinLeave", {
        group = resize_group,
        callback = function()
          local win = vim.api.nvim_get_current_win()
          if not vim.api.nvim_win_is_valid(win) then return end
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype

          if panel_filetypes[ft] then
            -- Reset to default size (clear overrides)
            vim.w[win].edgy_width = nil
            vim.w[win].edgy_height = nil
            Layout.update()
          end
        end,
        desc = "Shrink unfocused edge panel to default",
      })
    end,
    opts = {
      animate = { enabled = false },
      wo = {
        winfixwidth = true,
        winfixheight = true,
      },
      left = {
        { ft = "nerdtree", size = { width = 30 } },
      },
      bottom = {
        {
          ft = "toggleterm",
          size = { height = 0.3 },
          filter = function(buf, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        { ft = "qf", title = "QuickFix" },
      },
      right = {
        {
          ft = "opencode_terminal",
          title = "OpenCode",
          size = { width = 0.35 },
        },
      },
    },
    keys = {
      { "<leader>el", function() require("edgy").toggle("left") end, desc = "Toggle left panel" },
      { "<leader>eb", function() require("edgy").toggle("bottom") end, desc = "Toggle bottom panel" },
      { "<leader>er", function() require("edgy").toggle("right") end, desc = "Toggle right panel" },
    },
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

  -- Terminal (edgy.nvim pins it to bottom)
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { "<Leader>c", desc = "Toggle terminal" },
      { "<C-t>", desc = "Toggle terminal" },
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
  • <leader>k - Signature help        • <space>D - Type definition
  
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

  -- OpenCode - AI coding assistant (nickjvandyke/opencode.nvim)
  -- edgy.nvim pins this to the right edge via ft=opencode_terminal
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    config = function()
      -- Tag opencode terminal buffers so edgy.nvim can route them
      local function tag_opencode_buf()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].buftype == "terminal" then
            local name = vim.api.nvim_buf_get_name(buf)
            if name:match("opencode") and vim.bo[buf].filetype ~= "opencode_terminal" then
              vim.bo[buf].filetype = "opencode_terminal"
            end
          end
        end
      end

      -- Force the opencode TUI to redraw after window resize
      local function redraw_opencode_terminal()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype == "opencode_terminal" then
            local job_id = vim.b[buf].terminal_job_id
            if job_id then
              -- Notify the terminal process of new dimensions via SIGWINCH
              local width = vim.api.nvim_win_get_width(win)
              local height = vim.api.nvim_win_get_height(win)
              pcall(vim.fn.jobresize, job_id, width, height)
            end
            return
          end
        end
      end

      local function ensure_opencode_visible()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype == "opencode_terminal" then
            return
          end
        end

        require("opencode").toggle()
        vim.schedule(tag_opencode_buf)
      end

      local function add_context_to_opencode_prompt(context_ref)
        local context = require("opencode.context").new()

        ensure_opencode_visible()
        require("opencode").prompt(context_ref .. " ", { context = context })
      end

      -- Redraw on window layout changes
      vim.api.nvim_create_autocmd("WinResized", {
        callback = function()
          vim.schedule(redraw_opencode_terminal)
        end,
      })

      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          start = function()
            require("opencode.terminal").start("opencode --port")
            vim.schedule(tag_opencode_buf)
          end,
          toggle = function()
            local terminal = require("opencode.terminal")
            if #vim.api.nvim_tabpage_list_wins(0) == 1 then
              vim.cmd("enew")
            end
            terminal.toggle("opencode --port")
            vim.schedule(tag_opencode_buf)
          end,
        },
      }
      vim.o.autoread = true

      -- <leader>o prefix (leader=s, so so...)
      vim.keymap.set("n", "<leader>o", function() add_context_to_opencode_prompt("@buffer") end, { desc = "Add buffer to opencode prompt" })
      vim.keymap.set("x", "<leader>o", function() add_context_to_opencode_prompt("@this") end, { desc = "Add selection to opencode prompt" })
      vim.keymap.set({ "n", "t" }, "<leader>oo", function() require("opencode").toggle() end, { desc = "Toggle opencode" })
      vim.keymap.set({ "n", "x" }, "<leader>oa", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode" })
      vim.keymap.set({ "n", "x" }, "<leader>os", function() require("opencode").select() end, { desc = "Select opencode action" })

      -- go operator: send range/selection to opencode (dot-repeatable)
      vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end, { desc = "Send range to opencode", expr = true })
      vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Send line to opencode", expr = true })
    end,
  }
}
