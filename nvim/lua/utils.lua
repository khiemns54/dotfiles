local M = {}

function M.prequire(...)
  local status, lib = pcall(require, ...)
  if (status) then return lib end
  return nil
end

function M.packer_lazy_load(plugin, timer)
  if plugin then
    timer = timer or 0
    vim.defer_fn(function()
      require("packer").loader(plugin)
    end, timer)
  end
end

function M.disable_builtins(plugs)
  for _, plug in pairs(plugs) do
    vim.g["loaded_" .. plug] = 1
  end
end

function M.getenv(name, default)
  local ret = vim.fn.getenv(name)
  if ret == vim.NIL then
    return default
  end
  return ret
end

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔄 CONFIGURATION RELOAD SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- Complete reload system that clears cache, reloads config, and reinstalls plugins
-- Usage: :ReloadAll or lua require('utils').reload_all()

function M.clear_module_cache()
  -- Clear Lua module cache to force reload of all modules
  for name, _ in pairs(package.loaded) do
    if name:match('^default') or 
       name:match('^plugins') or 
       name:match('^keybinding') or 
       name:match('^modules%.') or
       name:match('^utils') then
      package.loaded[name] = nil
    end
  end
end

function M.clear_autocmds()
  -- Clear potentially conflicting autocommands
  vim.cmd('autocmd!')
  -- Clear packer autocommands specifically
  vim.cmd('augroup packer_auto_compile | autocmd! | augroup END')
end

function M.reload_config()
  -- Clear cache first
  M.clear_module_cache()
  
  -- Clear autocmds to prevent conflicts
  M.clear_autocmds()
  
  -- Reload core configuration files
  local config_files = {'default', 'plugins', 'keybinding'}
  
  for _, config in ipairs(config_files) do
    local ok, err = pcall(require, config)
    if not ok then
      vim.notify(string.format("❌ Failed to reload %s: %s", config, err), vim.log.levels.ERROR)
      return false
    end
  end
  
  return true
end

function M.reload_all()
  vim.notify("🔄 Starting complete configuration reload...", vim.log.levels.INFO)
  
  -- Step 1: Reload configuration
  vim.notify("📁 Reloading configuration files...", vim.log.levels.INFO)
  if not M.reload_config() then
    vim.notify("❌ Configuration reload failed!", vim.log.levels.ERROR)
    return
  end
  
  -- Step 2: Reinstall and sync plugins
  vim.notify("📦 Syncing plugins with Packer...", vim.log.levels.INFO)
  
  -- Ensure packer is available
  local packer_ok, packer = pcall(require, 'packer')
  if not packer_ok then
    vim.notify("❌ Packer not available!", vim.log.levels.ERROR)
    return
  end
  
  -- Clean, install, and sync plugins
  vim.defer_fn(function()
    packer.clean()
    vim.defer_fn(function()
      packer.sync()
      vim.defer_fn(function()
        vim.notify("✅ Configuration reload complete! All plugins synced.", vim.log.levels.INFO)
        vim.notify("💡 If you see any errors, try running :PackerSync manually", vim.log.levels.WARN)
      end, 1000)
    end, 1000)
  end, 500)
end

-- Alternative function for quick config reload without plugin sync
function M.reload_config_only()
  vim.notify("🔄 Reloading configuration (no plugin sync)...", vim.log.levels.INFO)
  
  if M.reload_config() then
    vim.notify("✅ Configuration reloaded successfully!", vim.log.levels.INFO)
  else
    vim.notify("❌ Configuration reload failed!", vim.log.levels.ERROR)
  end
end

return M
