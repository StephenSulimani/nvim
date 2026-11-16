return {
	"milanglacier/minuet-ai.nvim",
	event = "InsertEnter",
	enabled = false,
	cmd = "Minuet",
	config = function()
		require("minuet").setup({
			provider = "gemini",
			n_completions = 1,
			throttle = 1500,
			debounce = 600,
			request_timeout = 6,
			virtualtext = {
				auto_trigger_ft = { "*" },
				auto_trigger_ignore_ft = {
					"TelescopePrompt",
					"neo-tree",
					"lazy",
					"mason",
					"help",
				},
				keymap = {
					accept = "<C-z>",
					next = "<C-]>",
					prev = "<C-[>",
				},
				show_on_completion_menu = true,
			},
			-- Ghost text only. nvim-cmp stays on LSP, snippets, and buffer.
			lsp = {
				completion = {
					enable = false,
				},
			},
			provider_options = {
				gemini = {
					model = "gemini-3.5-flash-lite",
					api_key = "GEMINI_API_KEY",
					optional = {
						generationConfig = {
							maxOutputTokens = 256,
							thinkingConfig = {
								thinkingLevel = "minimal",
							},
						},
					},
				},
			},
		})
		-- Keep <Esc> distinct from the <C-[> previous-suggestion binding.
		vim.api.nvim_set_keymap("i", "<Esc>", "<Esc>", { noremap = true, silent = true })
	end,
}
