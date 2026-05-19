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
				on_attach = function(client, bufnr)
					-- Format on save is handled by conform.nvim (gofumpt).
					-- Organize imports via gopls (faster and more reliable than goimports on save).
					if client.name == "gopls" then
						vim.api.nvim_create_autocmd("BufWritePre", {
							buffer = bufnr,
							group = vim.api.nvim_create_augroup("LspGoOrganizeImports", { clear = false }),
							callback = function()
								vim.lsp.buf.code_action({
									context = { only = { "source.organizeImports" } },
									apply = true,
								})
							end,
						})
					end
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
