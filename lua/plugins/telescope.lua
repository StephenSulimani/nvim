return {
	{
		"nvim-telescope/telescope.nvim",
		-- 0.1.x calls nvim-treesitter.parsers.ft_to_lang (removed on treesitter main)
		version = "0.2.2",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")

			telescope.setup({
				history = false,
				preview = {
					-- Avoid ft_to_lang crash if an old telescope build is still on disk
					treesitter = false,
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			telescope.load_extension("ui-select")

			vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
		end,
	},
}
