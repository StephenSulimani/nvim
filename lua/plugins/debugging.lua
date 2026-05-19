return {
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			vim.keymap.set("n", "<leader>D", dap.continue)
			vim.keymap.set("n", "<leader>B", dap.toggle_breakpoint)
			vim.keymap.set("n", "<leader>Si", dap.step_into)
			vim.keymap.set("n", "<leader>So", dap.step_over)
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
