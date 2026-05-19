return {
	"romgrk/barbar.nvim",
	dependencies = {
		"lewis6991/gitsigns.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		vim.g.barbar_auto_setup = false
		vim.keymap.set("n", "<Tab>", ":BufferNext<CR>", {})
		vim.keymap.set("n", "<S-Tab>", ":BufferPrevious<CR>", {})
		vim.keymap.set("n", "<C-w>", ":BufferClose<CR>", {})
	end,
}
