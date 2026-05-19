return {
	{
		"ray-x/lsp_signature.nvim",
		config = function()
			local lsp_sig = require("lsp_signature")
			vim.keymap.set({ "n", "i" }, "<C-q>", function()
				lsp_sig.toggle_float_win()
			end, { silent = true, noremap = true, desc = "toggle signature" })
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"goimports",
					"gofumpt",
				},
			})
		end,
	},
	{
		"junnplus/lsp-setup.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			capabilities.textDocument.completion.completionItem.snippetSupport = true

			require("lsp-setup").setup({
				capabilities = capabilities,
				on_attach = function(_client, _bufnr)
					-- Format on save is handled by conform.nvim
				end,
				servers = {
					gopls = {},
					pyright = {},
					clangd = {
						cmd = {
							"clangd",
							"--header-insertion=iwyu",
							"--completion-style=detailed",
							"--function-arg-placeholders",
							"--fallback-style=llvm",
						},
					},
					eslint = {},
					prismals = {},
					ts_ls = {
						flags = { debounce_text_changes = 300 },
					},
					phpstan = {},
					tailwindcss = {},
					neocmake = {
						cmd = { "neocmakelsp", "stdio" },
						filetypes = { "cmake" },
					},
					postgres_lsp = {},
					intelephense = {},
				},
			})
		end,
	},
}
