return {
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
