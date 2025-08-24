local vscode = require("vscode")

vim.keymap.set("n", "<leader>p", function()
  vim.fn.VSCodeNotify("workbench.action.quickOpen")
end, { silent = true, desc = "Fuzzy file search" })


vim.keymap.set("n", "<leader>P", function()
  vim.fn.VSCodeNotify("workbench.action.showCommands")
end, { silent = true, desc = "Fuzzy file search" })

vim.keymap.set("n", "<leader>c", function()
  vscode.call("workbench.action.quickOpenTerm")
end, { silent = true, desc = "Toggle terminal (focus or create)" })

vim.keymap.set("n", "<leader>f", function()
  vscode.call("workbench.view.explorer")
end, { silent = true, desc = "Togple terminal" })


vim.keymap.set("n", "<leader>b", function()
  vscode.call("workbench.action.showAllEditors")
end, { silent = true, desc = "Togple terminal" })