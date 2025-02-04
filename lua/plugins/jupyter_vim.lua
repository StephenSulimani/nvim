return {
    "jupyter-vim/jupyter-vim",
    config = function()
        vim.keymap.set('n',  '<leader>X', ':JupyterSendCell<CR>', {})
        vim.keymap.set('n', '<leader>x', ':JupyterRunFile<CR>', {})
    end
}
