local function uv_available()
	return vim.fn.executable("uv") == 1
end

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
				desc = "Select Python virtualenv (uv .venv)",
			},
		},
		opts = {
			options = {
				picker = "telescope",
				notify_user_on_venv_activation = true,
				cached_venv_automatic_activation = true,
				enable_default_searches = true,
			},
			-- Default fd searches find uv's `.venv` in cwd/workspace; PEP 723 scripts use uv automatically.
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
			if uv_available() then
				require("dap-python").setup("uv")
			else
				local python = "python3"
				local ok, registry = pcall(require, "mason-registry")
				if ok and registry.is_installed("debugpy") then
					python = registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
				end
				require("dap-python").setup(python)
				vim.notify("uv not in PATH — using Mason debugpy for DAP", vim.log.levels.WARN)
			end
			require("dap-python").test_runner = "pytest"
			require("pycoverage").setup()
		end,
	},
}
