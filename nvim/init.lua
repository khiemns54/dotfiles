require("default")
if not vim.g.vscode then
   -- Bootstrap lazy.nvim
   local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
   if not (vim.uv or vim.loop).fs_stat(lazypath) then
     local lazyrepo = "https://github.com/folke/lazy.nvim.git"
     local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
     if vim.v.shell_error ~= 0 then
       vim.api.nvim_echo({
         { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
         { out, "WarningMsg" },
         { "\nPress any key to exit..." },
       }, true, {})
       vim.fn.getchar()
       os.exit(1)
     end
   end
   vim.opt.rtp:prepend(lazypath)

   -- Setup lazy.nvim
   require("lazy").setup("lazy-plugins", {
     ui = {
       -- If you have a Nerd Font, set icons to an empty table which will use the default lazy.nvim defined Nerd Font icons
       icons = vim.g.have_nerd_font and {} or {
         cmd = "⌘",
         config = "🛠",
         event = "📅",
         ft = "📂",
         init = "⚙",
         keys = "🗝",
         plugin = "🔌",
         runtime = "💻",
         source = "📄",
         start = "🚀",
         task = "📌",
       },
     },
   })
else
   require("vscode_conf")
end
