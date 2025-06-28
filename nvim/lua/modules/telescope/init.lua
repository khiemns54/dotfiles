local _M = {}
local vimp = require("vimp")

function _M.setup()
  vimp.nnoremap("<leader>p", ":Telescope find_files<cr>")
  vimp.nnoremap("<leader>g", ":Telescope live_grep<cr>")
  vimp.nnoremap("<leader>b", ":Telescope buffers<cr>")
  vimp.nnoremap("<leader>P", ":Telescope<cr>")
end

function _M.config()
  local actions = require('telescope.actions')

  require('telescope').setup{
    defaults = {
      vimgrep_arguments = {
         "rg",
         "--color=never",
         "--no-heading",
         "--with-filename",
         "--line-number",
         "--column",
         "--smart-case",
         "--hidden",
      },
      sorting_strategy = "ascending",
      file_ignore_patterns = {
        ".git/", "node_modules/", "target/", "bin/", "vendor/", ".DS_Store/",
        ".gradle/", "*.class", ".DS_Store",
        "build/",
      },
      mappings = {
        n = {
          ["<esc>"] = actions.close,
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
        },
        i = {
          ["<esc>"] = actions.close,
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
        }
      }
    },
    pickers = {
      find_files = {
        -- More conservative settings
        find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
      },
      live_grep = {
        additional_args = function(opts)
          return {"--hidden", "--glob", "!.git/*"}
        end
      },
    },
  }
end

return _M
