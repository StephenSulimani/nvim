return {
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"neovim/nvim-lspconfig",
		},
		ft = "python",
		keys = {
			{
				"<leader>cv",
				"<cmd>VenvSelect<cr>",
				desc = "Select Python virtualenv",
			},
		},
		opts = {
			name = {
				"venv",
				".venv",
				"env",
				".env",
			},
			search_venv_managers = {
				"pipenv",
				"poetry",
				"uv",
				"pyenv",
				"virtualenvwrapper",
			},
			search = {
				cwd = "projectDir",
				ignore_dirs = {
					"node_modules",
					"dist",
					".git",
				},
			},
			options = {
				picker = "telescope",
			},
		},
	},
	{
		"mfussenegger/nvim-dap-python",
		dependencies = {
			"mfussenegger/nvim-dap",
			"rcarriga/nvim-dap-ui",
		},
		ft = "python",
		config = function()
			local python = "python3"
			local ok, registry = pcall(require, "mason-registry")
			if ok and registry.is_installed("debugpy") then
				python = registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
			end
			require("dap-python").setup(python)
		end,
	},
}
