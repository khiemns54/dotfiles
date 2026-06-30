local _M = {}

local project_tabs = {
  { label = "Files", kind = "files" },
  { label = "Search", kind = "search" },
  { label = "Buffers", kind = "buffers" },
  { label = "Classes", kind = "symbols", symbols = { "class", "enum", "struct", "interface" } },
  { label = "Git status", kind = "git" },
}

local function filename_path_display(path, prefix)
  local utils = require("telescope.utils")
  local filename = vim.fn.fnamemodify(path, ":t")
  local relative_path = vim.fn.fnamemodify(path, ":.")
  local dirname = vim.fn.fnamemodify(relative_path, ":h")
  local icon, icon_hl = utils.get_devicons(filename)
  local icon_prefix = icon ~= "" and (icon .. " ") or ""
  local display = icon_prefix .. (prefix or "") .. filename
  local path_start

  if prefix then
    display = icon_prefix .. prefix .. " - " .. relative_path
    path_start = #icon_prefix + #prefix + 3
  elseif dirname ~= "." and dirname ~= "" then
    display = display .. " - " .. dirname
    path_start = #icon_prefix + #filename + 3
  end

  local highlights = {}

  if icon_hl and icon_prefix ~= "" then
    table.insert(highlights, { { 0, #icon }, icon_hl })
  end

  if path_start and path_start <= #display then
    table.insert(highlights, { { path_start, #display }, "TelescopePathItalic" })
  end

  return display, highlights
end

local function render_project_tabs(active_index)
  local tabs = {}

  for index, tab in ipairs(project_tabs) do
    if index == active_index then
      table.insert(tabs, "* " .. tab.label)
    else
      table.insert(tabs, "  " .. tab.label)
    end
  end

  return "Project  " .. table.concat(tabs, " | ")
end

local function project_files()
  return vim.fn.systemlist({
    "rg", "--files", "--hidden",
    "--glob", "!.git/*",
    "--glob", "!*.png",
    "--glob", "!*.jpg",
    "--glob", "!*.jpeg",
    "--glob", "!*.gif",
    "--glob", "!*.bmp",
    "--glob", "!*.ico",
    "--glob", "!*.svg",
    "--glob", "!*.webp",
    "--glob", "!*.pdf",
    "--glob", "!*.zip",
    "--glob", "!*.tar.gz",
    "--glob", "!*.jar",
    "--glob", "!*.war",
    "--glob", "!*.ear",
    "--glob", "!*.so",
    "--glob", "!*.dylib",
    "--glob", "!*.dll",
    "--glob", "!*.exe",
    "--glob", "!*.o",
    "--glob", "!*.a",
    "--glob", "!*.woff",
    "--glob", "!*.woff2",
    "--glob", "!*.ttf",
    "--glob", "!*.eot",
    "--glob", "!*.mp3",
    "--glob", "!*.mp4",
    "--glob", "!*.mov",
    "--glob", "!*.avi",
    "--glob", "!*.lock",
  })
end

local function git_status_entries()
  local lines = vim.fn.systemlist({ "git", "status", "--short", "--untracked-files=all" })
  local entries = {}

  for _, line in ipairs(lines) do
    local path = line:sub(4)
    path = path:match(".* %-> (.*)") or path
    table.insert(entries, {
      value = line,
      ordinal = line,
      display = line,
      filename = path,
      lnum = 1,
      col = 1,
    })
  end

  return entries
end

local function buffer_entries()
  local bufnrs = vim.tbl_filter(function(bufnr)
    return vim.fn.buflisted(bufnr) == 1
  end, vim.api.nvim_list_bufs())

  table.sort(bufnrs, function(a, b)
    return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
  end)

  return vim.tbl_map(function(bufnr)
    return {
      bufnr = bufnr,
      flag = bufnr == vim.fn.bufnr("") and "%" or (bufnr == vim.fn.bufnr("#") and "#" or " "),
      info = vim.fn.getbufinfo(bufnr)[1],
    }
  end, bufnrs)
end

local function collect_workspace_symbols(callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local cwd = vim.uv.cwd()
  local clients = vim.tbl_filter(function(client)
    local supports_symbols = client.supports_method and client:supports_method("workspace/symbol")
    local root = client.config and client.config.root_dir

    if not supports_symbols then
      return false
    end

    if client.attached_buffers and client.attached_buffers[bufnr] then
      return true
    end

    if root and path ~= "" and vim.startswith(vim.fs.normalize(path), vim.fs.normalize(root)) then
      return true
    end

    return root and cwd and vim.startswith(vim.fs.normalize(cwd), vim.fs.normalize(root))
  end, vim.lsp.get_clients())

  if vim.tbl_isempty(clients) then
    callback({})
    return
  end

  local pending = #clients
  local locations = {}

  local function complete_request()
    pending = pending - 1

    if pending == 0 then
      callback(locations)
    end
  end

  for _, client in ipairs(clients) do
    local ok = client:request("workspace/symbol", { query = "" }, function(err, result)
      if not err and result then
        vim.list_extend(locations, vim.lsp.util.symbols_to_items(result, bufnr, client.offset_encoding))
      end

      complete_request()
    end, bufnr)

    if not ok then
      complete_request()
    end
  end
end

local function filter_symbols(locations, symbols)
  if not symbols then
    return locations
  end

  return vim.tbl_filter(function(item)
    return item.kind and vim.tbl_contains(symbols, string.lower(item.kind))
  end, locations)
end

local function project_finder(tab_index, locations, entry_makers)
  local tab = project_tabs[tab_index]
  local finders = require("telescope.finders")

  if tab.kind == "files" then
    return finders.new_table({
      results = project_files(),
      entry_maker = entry_makers.file,
    })
  end

  if tab.kind == "search" then
    return finders.new_dynamic({
      fn = function(prompt)
        if prompt == "" then
          return {}
        end

        return vim.fn.systemlist({
          "rg",
          "--vimgrep",
          "--smart-case",
          "--hidden",
          "--glob",
          "!.git/*",
          prompt,
        })
      end,
      entry_maker = entry_makers.search,
    })
  end

  if tab.kind == "buffers" then
    return finders.new_table({
      results = buffer_entries(),
      entry_maker = entry_makers.buffer,
    })
  end

  if tab.kind == "git" then
    return finders.new_table({
      results = git_status_entries(),
      entry_maker = entry_makers.git,
    })
  end

  return finders.new_table({
    results = filter_symbols(locations, tab.symbols),
    entry_maker = entry_makers.symbol,
  })
end

local function open_project_picker(default_tab)
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local make_entry = require("telescope.make_entry")
  local pickers = require("telescope.pickers")
  local active_tab = default_tab or 1

  collect_workspace_symbols(function(locations)
    local opts = {
      prompt_title = render_project_tabs(active_tab),
      ignore_filename = false,
      bufnr_width = 3,
    }
    local entry_makers = {
      file = function(entry)
        return {
          value = entry,
          ordinal = entry,
          display = function(item)
            return filename_path_display(item.filename)
          end,
          filename = entry,
          path = entry,
          lnum = 1,
          col = 1,
        }
      end,
      search = make_entry.gen_from_vimgrep(opts),
      buffer = function(entry)
        local buffer_entry = make_entry.gen_from_buffer(opts)(entry)
        local prefix = buffer_entry.bufnr .. " " .. buffer_entry.indicator .. " "

        buffer_entry.display = function(item)
          return filename_path_display(item.path or item.filename, prefix)
        end

        return buffer_entry
      end,
      symbol = function(entry)
        local symbol_entry = make_entry.gen_from_lsp_symbols(opts)(entry)
        symbol_entry.ordinal = symbol_entry.symbol_name .. " " .. symbol_entry.symbol_type
        symbol_entry.display = function(item)
          return filename_path_display(item.filename, item.symbol_name .. " " .. item.symbol_type:lower())
        end

        return symbol_entry
      end,
      git = function(entry)
        return entry
      end,
    }

    pickers.new(opts, {
      finder = project_finder(active_tab, locations, entry_makers),
      previewer = conf.qflist_previewer(opts),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        local cycle = function(step)
          return function()
            active_tab = ((active_tab - 1 + step) % #project_tabs) + 1

            local picker = action_state.get_current_picker(prompt_bufnr)
            local title = render_project_tabs(active_tab)
            picker.prompt_title = title

            if picker.layout.prompt.border then
              picker.layout.prompt.border:change_title(title)
            end

            picker:refresh(project_finder(active_tab, locations, entry_makers), { reset_prompt = false })
          end
        end

        map("i", "<tab>", cycle(1))
        map("n", "<tab>", cycle(1))
        map("i", "<s-tab>", cycle(-1))
        map("n", "<s-tab>", cycle(-1))
        return true
      end,
    }):find()
  end)
end

function _M.project_picker(default_tab)
  open_project_picker(default_tab)
end

function _M.setup()
  vim.keymap.set("n", "<leader>p", function()
    _M.project_picker(1)
  end, { noremap = true, silent = true })
  vim.keymap.set("n", "<leader>g", function()
    _M.project_picker(2)
  end, { noremap = true, silent = true })
  vim.keymap.set("n", "<leader>b", function()
    _M.project_picker(3)
  end, { noremap = true, silent = true })
  vim.keymap.set("n", "<leader>P", ":Telescope<cr>", { noremap = true, silent = true })
end

function _M.config()
  local actions = require('telescope.actions')

  vim.api.nvim_set_hl(0, "TelescopePathItalic", { italic = true })

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
        find_command = {
          "rg", "--files", "--hidden",
          "--glob", "!.git/*",
          "--glob", "!*.png",
          "--glob", "!*.jpg",
          "--glob", "!*.jpeg",
          "--glob", "!*.gif",
          "--glob", "!*.bmp",
          "--glob", "!*.ico",
          "--glob", "!*.svg",
          "--glob", "!*.webp",
          "--glob", "!*.pdf",
          "--glob", "!*.zip",
          "--glob", "!*.tar.gz",
          "--glob", "!*.jar",
          "--glob", "!*.war",
          "--glob", "!*.ear",
          "--glob", "!*.so",
          "--glob", "!*.dylib",
          "--glob", "!*.dll",
          "--glob", "!*.exe",
          "--glob", "!*.o",
          "--glob", "!*.a",
          "--glob", "!*.woff",
          "--glob", "!*.woff2",
          "--glob", "!*.ttf",
          "--glob", "!*.eot",
          "--glob", "!*.mp3",
          "--glob", "!*.mp4",
          "--glob", "!*.mov",
          "--glob", "!*.avi",
          "--glob", "!*.lock",
        },
      },
      live_grep = {
        additional_args = function(opts)
          return {"--hidden", "--glob", "!.git/*"}
        end
      },
    },
    extensions = {
      ["ui-select"] = {
        require("telescope.themes").get_dropdown {}
      }
    }
  }
  require("telescope").load_extension("ui-select")
end




return _M
