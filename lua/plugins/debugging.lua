local function mason_codelldb()
	local bin = vim.fn.stdpath("data") .. "/mason/bin/codelldb"
	if vim.fn.executable(bin) == 1 then
		return bin
	end

	local ok, registry = pcall(require, "mason-registry")
	if not ok or not registry.is_installed("codelldb") then
		return nil
	end
	local root = registry.get_package("codelldb"):get_install_path()
	local candidates = {
		root .. "/extension/adapter/codelldb",
		root .. "/codelldb",
	}
	for _, path in ipairs(candidates) do
		if vim.fn.executable(path) == 1 then
			return path
		end
	end
	return nil
end

local function setup_cpp_dap()
	local dap = require("dap")
	local codelldb = mason_codelldb()
	if not codelldb then
		return
	end

	dap.adapters.codelldb = {
		type = "server",
		port = "${port}",
		executable = {
			command = codelldb,
			args = { "--port", "${port}" },
		},
	}

	local configs = {
		{
			name = "Launch file",
			type = "codelldb",
			request = "launch",
			program = function()
				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
			end,
			cwd = "${workspaceFolder}",
			stopOnEntry = false,
			args = {},
		},
		{
			name = "Attach to process",
			type = "codelldb",
			request = "attach",
			pid = require("dap.utils").pick_process,
			args = {},
		},
	}

	dap.configurations.cpp = configs
	dap.configurations.c = configs
end

return {
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			vim.keymap.set("n", "<leader>D", dap.continue)
			vim.keymap.set("n", "<leader>B", dap.toggle_breakpoint)
			vim.keymap.set("n", "<leader>Si", dap.step_into)
			vim.keymap.set("n", "<leader>So", dap.step_over)

			setup_cpp_dap()
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			local dapui = require("dapui")

			dapui.setup()

			vim.keymap.set("n", "<leader>d", dapui.toggle)
		end,
	},
	{
		"leoluz/nvim-dap-go",
		config = function()
			local dap_go = require("dap-go")
			dap_go.setup()
		end,
	},
}
