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
  use {"savq/melange", requires = {"rktjmp/lush.nvim"}, 
    config = function()
      vim.cmd("colorscheme melange")
    end
  }

  use {'glepnir/dashboard-nvim'}


  -- Terminal
  use {
    "akinsho/toggleterm.nvim",
    config = [[require('modules/terminal')]],
  }
end)

vim.g.dashboard_default_executive = 'telescope'
