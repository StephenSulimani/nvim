local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- vim.g.python3_host_prog = '/home/stephen/.local/share/mise/installs/python/3.13.2/bin/python3'

local function find_python3()
	local handle = io.popen("which python3") -- or "command -v python3" for more compatibility
	local result = handle:read("*a")
	handle:close()
	return result:gsub("%s+", "") -- Trim whitespace
end

local python3_path = find_python3()
if python3_path and python3_path ~= "" then
	vim.g.python3_host_prog = python3_path
else
	print("Python 3 executable not found. Please set vim.g.python3_host_prog manually.")
end

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
