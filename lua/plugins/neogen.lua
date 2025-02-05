return {
    "danymat/neogen",
    config = function()
        local neogen = require('neogen').setup({
            enabled = true,
            languages = {
                python = {
                    template = {
                        annotation_convention = "reST"
                    }
                }
            }
        })
        vim.keymap.set('n', '<leader>gd', ":lua require('neogen').generate()<CR>", {
            noremap = true,
            silent = true
        } )
    end
}
