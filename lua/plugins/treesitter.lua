return {
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" }, -- Ensures context loads after treesitter
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = true,
		build = ":TSUpdate",
		branch = "main",
		config = function()
			-- 1. Enable Native Tree-sitter Highlighting & Indentation
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					-- Enables native syntax highlighting
					pcall(vim.treesitter.start)
					-- Enables native tree-sitter based indentation (replaces indent = { enable = true })
					vim.bo.indentexpr = "v:lua.vim.treesitter.foldexpr()"
				end,
			})

			-- 2. Handle Auto-Installation (replaces auto_install = true)
			local install = require("nvim-treesitter.install")
			install.prefer_git = true

			-- Setup an autocommand to catch missing parsers on the fly
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local lang = vim.bo[args.buf].filetype
					-- Skip empty filetypes or special buffers
					if lang == "" or vim.bo[args.buf].buftype ~= "" then
						return
					end

					-- Map common filetype overrides if necessary (e.g., bash -> bash)
					lang = vim.treesitter.language.get_lang(lang) or lang

					-- Check if the parser is missing, and install if it is
					if lang and not pcall(vim.treesitter.query.get, lang, "highlights") then
						vim.cmd("TSInstall " .. lang)
					end
				end,
			})
		end,
	},
}
