return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        vim.keymap.set("n", "<C-n>", ":Neotree toggle<CR>", {})
        vim.keymap.set("n", "<C-G>", ":Neotree git_status<CR>", {})
        require("neo-tree").setup({
            close_if_last_window = true,
            filesystem = {
                filtered_items = {
                    always_show_by_pattern = {
                        ".env*",
                        ".gitignore",
                    },
                    hide_gitignored = false,
                    hide_by_name = {
                        "node_modules",
                    },
                },
            },
        })
    end,
}
