local function load_dotenv(path)
	local file = io.open(path, "r")
	if not file then
		return
	end
	for line in file:lines() do
		if not line:match("^%s*#") and not line:match("^%s*$") then
			local key, value = line:match("^%s*export%s+([%w_]+)%s*=%s*(.*)$")
			if not key then
				key, value = line:match("^%s*([%w_]+)%s*=%s*(.*)$")
			end
			if key and vim.env[key] == nil then
				value = vim.trim(value or "")
				local quote = value:sub(1, 1)
				if (quote == '"' or quote == "'") and value:sub(-1) == quote then
					value = value:sub(2, -2)
				end
				vim.env[key] = value
			end
		end
	end
	file:close()
end

load_dotenv(vim.fn.stdpath("config") .. "/.env")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

vim.opt.clipboard = "unnamedplus"

vim.opt.backupcopy = "yes"

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
require("cpp").setup()
