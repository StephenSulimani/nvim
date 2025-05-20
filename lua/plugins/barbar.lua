return {
	"romgrk/barbar.nvim",
	dependencies = {
		"lewis6991/gitsigns.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		vim.g.barbar_auto_setup = false
		vim.keymap.set("n", "<C-Tab>", ":BufferNext<CR>", {})
		vim.keymap.set("n", "<C-S-Tab>", ":BufferPrevious<CR>", {})
		vim.keymap.set("n", "<C-w>", ":BufferClose<CR>", {})
	end,
}
