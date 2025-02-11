return {
    "Exafunction/codeium.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp" },
    config = function()
        -- Change '<C-g>' here to any keycode you like.
        require("codeium").setup({
            virtual_text = {
                enabled = true,
                map_keys = true,
                key_bindings = {
                    accept = "<Tab>",
                    next = "<C-]>",
                    prev = "<C-[>",
                    accept_word = false,
                    accept_line = false,
                    clear = false,
                },
            },
        })
        vim.api.nvim_set_keymap("i", "<Esc>", "<Esc>", { noremap = true, silent = true })
    end,
}
