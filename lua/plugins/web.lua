local ts_inlay_hints = {
	includeInlayParameterNameHints = "all",
	includeInlayFunctionParameterTypeHints = true,
	includeInlayVariableTypeHints = true,
	includeInlayPropertyDeclarationTypeHints = true,
	includeInlayFunctionLikeReturnTypeHints = true,
}

local function setup_web_lsp()
	vim.lsp.config("ts_ls", {
		flags = { debounce_text_changes = 300 },
		settings = {
			typescript = {
				inlayHints = ts_inlay_hints,
				preferences = {
					importModuleSpecifier = "non-relative",
				},
			},
			javascript = {
				inlayHints = ts_inlay_hints,
				preferences = {
					importModuleSpecifier = "non-relative",
				},
			},
		},
	})

	vim.lsp.config("tailwindcss", {
		settings = {
			tailwindCSS = {
				experimental = {
					classRegex = {
						{ "className\\s*[:=]\\s*['\"]([^'\"]*)['\"]", "[^'\"\\s]+" },
						{ "class\\s*[:=]\\s*['\"]([^'\"]*)['\"]", "[^'\"\\s]+" },
					},
				},
			},
		},
	})

	vim.lsp.config("emmet_language_server", {
		filetypes = {
			"html",
			"css",
			"javascriptreact",
			"typescriptreact",
			"vue",
			"svelte",
		},
	})
	vim.lsp.enable("emmet_language_server")
end

return {
	{
		"windwp/nvim-ts-autotag",
		opts = {},
	},
	{
		event = "VeryLazy",
		config = function()
			setup_web_lsp()
		end,
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		dependencies = { "mfussenegger/nvim-dap" },
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
		config = function()
			local ok, registry = pcall(require, "mason-registry")
			if not ok or not registry.is_installed("js-debug-adapter") then
				vim.notify("js-debug-adapter not installed — run :MasonInstall js-debug-adapter", vim.log.levels.WARN)
				return
			end

			local debugger_path = registry.get_package("js-debug-adapter"):get_install_path()
			require("dap-vscode-js").setup({
				debugger_path = debugger_path,
				adapters = { "pwa-node", "pwa-chrome" },
			})

			local dap = require("dap")
			for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
				dap.configurations[lang] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
					},
				}
			end
		end,
	},
}
