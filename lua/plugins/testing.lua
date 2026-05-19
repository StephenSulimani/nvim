return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-neotest/neotest-python",
			"nvim-neotest/neotest-jest",
			"marilari88/neotest-vitest",
		},
		keys = {
			{
				"<leader>tt",
				function()
					require("neotest").run.run()
				end,
				desc = "Run nearest test",
			},
			{
				"<leader>tf",
				function()
					require("neotest").run.run(vim.fn.expand("%"))
				end,
				desc = "Run tests in file",
			},
			{
				"<leader>ts",
				function()
					require("neotest").summary.open()
				end,
				desc = "Test summary",
			},
			{
				"<leader>to",
				function()
					require("neotest").output.open()
				end,
				desc = "Test output",
			},
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-python")({
						runner = "pytest",
						dap = { justMyCode = false },
					}),
					require("neotest-jest")({
						jestCommand = "npm test --",
						jest_test_discovery = true,
					}),
					require("neotest-vitest")(),
				},
			})
		end,
	},
}
