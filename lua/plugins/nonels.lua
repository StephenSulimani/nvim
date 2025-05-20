return {
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"nvimtools/none-ls-extras.nvim",
		},
		config = function()
			local null_ls = require("null-ls")

			local formatting = null_ls.builtins.formatting

			null_ls.setup({
				sources = {
					formatting.stylua,
					formatting.gofmt,
				},
			})

			vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})

			vim.api.nvim_create_augroup("LspAutoFormat", { clear = true })

			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function()
					local clients = vim.lsp.get_clients()
					if #clients > 0 then
						vim.lsp.buf.format()
					else
						vim.cmd("Neoformat")
					end
				end,
				group = "LspAutoFormat",
			})
		end,
	},
}
