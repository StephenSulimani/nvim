return {
	"stevearc/conform.nvim",
	config = function()
		local conform = require("conform")
		conform.setup({
			format_on_save = {
				lsp_fallback = true,
				timeout_ms = 500,
			},
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "goimports", "gofumpt" },
				python = { "black" },
				javascript = { "prettierd", "eslint_d" },
				typescript = { "prettierd", "eslint_d" },
				typescriptreact = { "prettierd", "eslint_d" },
				json = { "prettierd" },
				html = { "prettierd" },
				css = { "prettierd" },
				sql = { "pg_format" },
				php = { "phpcbf" },
			},
			formatters = {
				autopep8 = {
					args = { "--in-place", "--aggressive", "--aggressive" },
				},
			},
		})

		vim.keymap.set("n", "<leader>gf", function()
			conform.format({ lsp_fallback = true })
		end, {})
	end,
}
