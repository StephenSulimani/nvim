-- Mason package bootstrap: clone this repo on a new machine and run Neovim once
-- to install all LSP servers and CLI tools used across the config.
return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"clangd",
					"eslint",
					"gopls",
					"intelephense",
					"jedi_language_server",
					"lua_ls",
					"neocmake",
					"phpstan",
					"postgres_lsp",
					"prismals",
					"pyright",
					"tailwindcss",
					"ts_ls",
				},
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"autopep8",
					"black",
					"eslint_d",
					"eugene",
					"gofumpt",
					"goimports",
					"pgformatter",
					"phpcbf",
					"prettierd",
					"stylua",
				},
				run_on_start = true,
			})
		end,
	},
}
