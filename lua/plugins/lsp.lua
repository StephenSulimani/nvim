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
	-- {
	-- 	"williamboman/mason.nvim",
	-- 	config = function()
	-- 		require("mason").setup()
	-- 	end,
	-- },
	-- {
	-- 	"williamboman/mason-lspconfig.nvim",
	-- 	config = function()
	-- 		require("mason-lspconfig").setup({
	-- 			ensure_installed = {},
	-- 		})
	-- 	end,
	-- },
	{
		"junnplus/lsp-setup.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			require("lsp-setup").setup({
				servers = {
					gopls = {},
					pyright = {},
					clangd = {},
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			capabilities.textDocument.completion.completionItem.snippetSupport = true
			local lspconfig = require("lspconfig")

			-- Individual LSP Setups

			-- lspconfig.gopls.setup({
			-- 	capabilities = capabilities,
			-- })

			-- lspconfig.pyright.setup({
			-- 	capabilities = capabilities,
			-- })

			-- Keybindings

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
