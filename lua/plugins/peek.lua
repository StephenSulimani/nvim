return {
	"toppair/peek.nvim",
	event = { "VeryLazy" },
	build = "deno task --quiet build:fast",
	enabled = false,
	config = function()
		local peek = require("peek")
		vim.api.nvim_create_user_command("PeekOpen", peek.open, { desc = "Open Peek" })
		vim.api.nvim_create_user_command("PeekClose", peek.close, { desc = "Close Peek" })
	end,
}
