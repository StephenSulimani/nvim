return {
	"stevearc/conform.nvim",
	config = function()
		local conform = require("conform")
		local util = require("conform.util")

		local uv_root = util.root_file({ "uv.lock", "pyproject.toml" })

		conform.setup({
			format_on_save = function(bufnr)
				-- goimports can be slow on first run or in large modules
				local timeout_ms = vim.bo[bufnr].filetype == "go" and 15000 or 3000
				return {
					timeout_ms = timeout_ms,
					lsp_fallback = true,
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofumpt" },
				python = function(bufnr)
					if vim.fs.root(bufnr, { "uv.lock" }) and vim.fn.executable("uv") == 1 then
						return { "ruff_fix_uv", "ruff_format_uv" }
					end
					return { "ruff_fix", "ruff_format" }
				end,
				javascript = { "prettierd", "eslint_d" },
				javascriptreact = { "prettierd", "eslint_d" },
				jsx = { "prettierd", "eslint_d" },
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
				ruff_fix_uv = {
					command = "uv",
					args = {
						"run",
						"ruff",
						"check",
						"--force-exclude",
						"--fix",
						"--stdin-filename",
						"$FILENAME",
						"-",
					},
					stdin = true,
					cwd = uv_root,
				},
				ruff_format_uv = {
					command = "uv",
					args = {
						"run",
						"ruff",
						"format",
						"--force-exclude",
						"--stdin-filename",
						"$FILENAME",
						"-",
					},
					stdin = true,
					cwd = uv_root,
				},
			},
		})

		vim.keymap.set("n", "<leader>gf", function()
			conform.format({ lsp_fallback = true })
		end, {})
	end,
}
