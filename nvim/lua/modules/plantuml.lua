local M = {}

local function find_plantuml_block()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local bufnr = 0
  local start_line
  local end_line

  -- search upward for start fence
  for l = cur, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1]
    if line and (line:match('^```%s*plantuml') or line:match('^```%s*uml')) then
      start_line = l
      break
    end
  end
  if not start_line then return nil end

  -- search downward for closing fence
  local last = vim.api.nvim_buf_line_count(bufnr)
  for l = start_line + 1, last do
    local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1]
    if line and line:match('^```%s*$') then
      end_line = l
      break
    end
  end

  if not end_line then return nil end
  return start_line, end_line
end

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, 'p')
  end
end

local function executable_or_jar()
  if vim.fn.executable('plantuml') == 1 then
    return { kind = 'bin' }
  end
  local jar = os.getenv('PLANTUML_JAR')
  if jar and #jar > 0 then
    return { kind = 'jar', jar = jar }
  end
  return nil
end

local function render_to_png(puml_text, out_png)
  local exec = executable_or_jar()
  if not exec then
    vim.notify('PlantUML not found. Install plantuml or set PLANTUML_JAR', vim.log.levels.ERROR)
    return false, 'no_plantuml'
  end

  local tmp_src = vim.fn.tempname() .. '.puml'
  local fd = assert(io.open(tmp_src, 'w'))
  fd:write(puml_text)
  fd:close()

  local cmd
  if exec.kind == 'bin' then
    cmd = string.format('plantuml -tpng %q', tmp_src)
  else
    cmd = string.format('java -jar %q -tpng %q', exec.jar, tmp_src)
  end

  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('PlantUML error: ' .. out, vim.log.levels.ERROR)
    return false, out
  end

  local generated = tmp_src:gsub('%.puml$', '.png')
  local ok, err = os.rename(generated, out_png)
  if not ok then
    -- fallback copy
    local in_f = io.open(generated, 'rb')
    local out_f = io.open(out_png, 'wb')
    if not in_f or not out_f then
      return false, err or 'move_failed'
    end
    out_f:write(in_f:read('*a'))
    in_f:close()
    out_f:close()
    os.remove(generated)
  end
  return true
end

local function insert_or_update_image_link(end_line, rel_path)
  local bufnr = 0
  local next_line_idx = end_line -- 1-based -> position after fence
  local lines = vim.api.nvim_buf_get_lines(bufnr, next_line_idx, next_line_idx + 1, false)
  local link = string.format('![plantuml](%s)', rel_path)
  if #lines > 0 and lines[1]:match('!%[[^%]]*%]%([^)]*%.png%)') then
    -- replace existing image link
    vim.api.nvim_buf_set_lines(bufnr, next_line_idx, next_line_idx + 1, false, { link })
  else
    vim.api.nvim_buf_set_lines(bufnr, next_line_idx, next_line_idx, false, { link })
  end
end

function M.render_under_cursor()
  local start_line, end_line = find_plantuml_block()
  if not start_line then
    vim.notify('No PlantUML block found near cursor', vim.log.levels.WARN)
    return
  end

  local bufnr = 0
  local content = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line - 1, false)
  local puml = table.concat(content, '\n')

  -- Output path: <current_file_dir>/diagrams/<basename>-<startline>.png
  local file = vim.api.nvim_buf_get_name(bufnr)
  local file_dir = vim.fn.fnamemodify(file, ':h')
  local base = vim.fn.fnamemodify(file, ':t:r')
  local out_dir = file_dir .. '/diagrams'
  ensure_dir(out_dir)
  local out_png = string.format('%s/%s-%d.png', out_dir, base, start_line)

  local ok = render_to_png(puml, out_png)
  if not ok then return end

  local rel = vim.fn.relpath(out_png, file_dir)
  insert_or_update_image_link(end_line, rel)
  vim.notify('PlantUML rendered → ' .. rel, vim.log.levels.INFO)
end

function M.setup()
  -- User command and a convenient keymap for Markdown buffers
  if M._set then return end
  M._set = true
  vim.api.nvim_create_user_command('PlantUMLRender', function()
    M.render_under_cursor()
  end, { desc = 'Render current PlantUML code block to PNG and insert image link' })

  vim.keymap.set('n', '<leader>up', function()
    M.render_under_cursor()
  end, { desc = 'PlantUML: render block', silent = true })
end

return M
