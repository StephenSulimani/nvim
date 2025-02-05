return {
    {
        "ray-x/lsp_signature.nvim",
        config = function()
            local lsp_sig = require("lsp_signature")
            vim.keymap.set({ "n", "i" }, "<C-q>", function()
                --                vim.lsp.buf.signature_help()
                lsp_sig.toggle_float_win()
            end, { silent = true, noremap = true, desc = "toggle signature" })
        end,
    },
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "ts_ls",
                    "dockerls",
                    "jedi_language_server",
                    "prismals",
                    "svelte",
                    "clangd",
                    "pyright",
                    "gopls",
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true
            local lspconfig = require("lspconfig")

            lspconfig.lua_ls.setup({
                capabilities = capabilities,
            })
            lspconfig.ts_ls.setup({
                capabilities = capabilities,
            })

            lspconfig.html.setup({
                capabilities = capabilities,
            })

            lspconfig.prismals.setup({
                capabilities = capabilities,
            })

            lspconfig.svelte.setup({
                capabilities = capabilities,
            })

            lspconfig.jedi_language_server.setup({
                capabilities = capabilities,
            })

            lspconfig.clangd.setup({
                capabilities = capabilities,
            })

            lspconfig.pyright.setup({
                capabilities = capabilities,
            })

            lspconfig.gopls.setup({
                capabilities = capabilities,
            })

            vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
        end,
    },
}
