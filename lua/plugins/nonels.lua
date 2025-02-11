return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				require("none-ls.diagnostics.eslint_d"),
				null_ls.builtins.formatting.prettier.with({
					filetypes = { "json", "ts", "js" },
				}),
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.isort,
				null_ls.builtins.formatting.clang_format,
				null_ls.builtins.diagnostics.pylint,
				null_ls.builtins.diagnostics.golangci_lint,
				null_ls.builtins.formatting.gofmt,
			},
		})
		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})

		-- Create an autocommand group
		vim.api.nvim_create_augroup("LspAutoFormat", { clear = true })

		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*",
			callback = function()
				local clients = vim.lsp.get_active_clients()
				if #clients > 0 then
					vim.lsp.buf.format()
				end
			end,
			group = "LspAutoFormat",
		})
	end,
}
