return {
    "luk400/vim-jukit",
    config = function()
        vim.g.jukit_convert_open_default = 0
        local function safe_unmap(mode, lhs)
            local mappings = vim.api.nvim_get_keymap(mode)
            for _, mapping in ipairs(mappings) do
                if mapping.lhs == lhs then
                    vim.api.nvim_del_keymap(mode, lhs)
                    return
                end
            end
        end
        safe_unmap("n", "<leader><CR>")
        vim.api.nvim_set_keymap(
            "n",
            "<leader><CR>",
            "<Cmd>call jukit#send#line()<CR>",
            { noremap = true, silent = true }
        )
    end,
}
