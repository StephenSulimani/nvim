local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

vim.opt.clipboard = "unnamedplus"

local function copy_to_clipboard()
	local current_selection = vim.fn.getreg('"')
	local handle = io.popen("xclip -selection clipboard", "w")
	handle:write(current_selection)
	handle:close()
end

vim.api.nvim_set_keymap("v", "<leader>y", [[:lua copy_to_clipboard()<CR>]], { noremap = true, silent = true })

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("vim-options")
require("lazy").setup("plugins")
