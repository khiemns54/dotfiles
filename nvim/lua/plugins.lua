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

  -- LSP
  use { 'neovim/nvim-lspconfig',
    config = [[require'modules/lsp']],
    setup = function()
      require("utils").packer_lazy_load("nvim-lspconfig")
      vim.defer_fn(function()
        if vim.bo.filetype ~= "packer" then
          vim.cmd "silent! e %"
        end
      end, 0)
    end,
  }
  
  use {
    'kabouzeid/nvim-lspinstall',
    config = function()
      require'lspinstall'.setup()
    end
  }

  use { 'nvim-lua/lsp-status.nvim', config = [[require'modules/lspstatus']],
      after = 'nvim-lspconfig',
    }
    use { 'ray-x/lsp_signature.nvim',
      after = {'nvim-lspconfig'},
      config = [[require'modules/lspsignature']]
    }

  use {
    "hrsh7th/nvim-cmp",
    config = [[require'modules/cmp']],
    requires = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lua",
    },
    run = function()
      require("modules.cmp").config()
    end,
  }

  use {
    'glepnir/lspsaga.nvim',
    disable = false,
    config = [[require'modules/lspsaga']]
  }

  use { 'kosayoda/nvim-lightbulb',
    config = function()
      vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]
    end
  }


  -- Treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate',
    config = [[require'modules/treesitter']],
    event = 'BufRead',
  }
  use { 'windwp/nvim-ts-autotag', after = 'nvim-treesitter', }
  use { 'RRethy/nvim-treesitter-textsubjects', after = 'nvim-treesitter'}
  use { 'nvim-treesitter/playground', after = 'nvim-treesitter', }

  -- Status
  use {
    'hoob3rt/lualine.nvim',
    requires = {
      'kyazdani42/nvim-web-devicons',
      opt = true,
      config = function()
        require'nvim-web-devicons'.get_icons()
      end
    },
    config = [[require'modules/lualine']]
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
        nmap <C-n> :NERDTreeToggle<CR>
        nnoremap <silent> <Leader>t :NERDTreeFocus<CR>
        nnoremap <silent> <Leader>f :NERDTreeFind<CR>
        let NERDTreeQuitOnOpen=1
      ]]
    end
  }

  -- UI
  use {"ellisonleao/gruvbox.nvim", requires = {"rktjmp/lush.nvim"}}
  use {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("indent_blankline").setup {
        char = "|",
        buftype_exclude = {"terminal"},
        use_treesitter = true,
      }
    end
  }

  use {'glepnir/dashboard-nvim'}

  -- Terminal
  use {
    "akinsho/toggleterm.nvim",
    config = [[require('modules/terminal')]],
  }
end)

vim.cmd("colorscheme gruvbox")
vim.g.dashboard_default_executive = 'telescope'
