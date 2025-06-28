-- Modern nvim-treesitter configuration with error handling
local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
  vim.notify("nvim-treesitter.configs not found!", vim.log.levels.ERROR)
  return
end

-- Try to add custom parser configuration safely
local parser_status_ok, parser_config = pcall(require, "nvim-treesitter.parsers")
if parser_status_ok then
  local parsers = parser_config.get_parser_configs()
  
  -- Try to register the custom toon parser if the path exists
  local toon_parser_path = vim.fn.expand("~/Workspaces/toon-lang/tree-sitter-toon")
  if vim.fn.isdirectory(toon_parser_path) == 1 then
    parsers.toon = {
      install_info = {
        url = toon_parser_path,
        files = {"src/parser.c"}
      },
      filetype = "toon",
    }
  end
else
  vim.notify("nvim-treesitter.parsers not available - skipping custom parser registration", vim.log.levels.WARN)
end

configs.setup {
  ensure_installed = {
    "bash", "css", "dart", "go", "gomod", "html", "javascript",
    "json", "lua", "python", "fish", "comment", "query", "nix",
    "java", "kotlin", "ruby",
    "rust", "toml", "tsx", "typescript", "vue", "yaml" },

  highlight = {
    enable = true,
  },

  indent = {
    enable = true,
    disable = { "python" },
  },

  playground = {
    enable = true,
  },

  autotag = {
    enable = true
  },

  textsubjects = {
    enable = true,
    keymaps = {
      ['.'] = 'textsubjects-smart',
      ['<CR>'] = 'textsubjects-big',
    }
  },
}

vim.cmd [[set foldmethod=expr]]
vim.cmd [[set foldexpr=nvim_treesitter#foldexpr()]]
