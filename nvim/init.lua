require("default")
if not vim.g.vscode then
   require("plugins")
else
   require("vscode_conf")
end
