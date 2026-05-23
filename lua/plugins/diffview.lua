return {
	"sindrets/diffview.nvim",
	config = function()
		local function diffview_close()
			-- Diffview closes its tab with :tabclose, which raises E445 when another
			-- window in that tab is modified (common when reviewing a PR diff).
			local hidden = vim.o.hidden
			vim.o.hidden = true
			pcall(require("diffview").close)
			vim.o.hidden = hidden
		end

		vim.keymap.set("n", "<leader>dc", function()
			if next(require("diffview.lib").views) == nil then
				vim.cmd("DiffviewOpen")
			else
				diffview_close()
			end
		end)
	end,
}
