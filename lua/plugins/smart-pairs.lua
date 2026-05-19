return {
	"ZhiyuanLck/smart-pairs",
	config = function()
		require("pairs"):setup({
			enter = {
				enable_mapping = false,
			},
		})
	end,
}
