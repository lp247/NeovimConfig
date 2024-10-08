-- General Configuration
----------------------------------------------------------------------------
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
vim.opt.wildignore:append { "node_modules" }
if vim.fn.has("win32") == 1 then
    vim.opt.shell = "powershell.exe"
    vim.opt.shellcmdflag =
        "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    vim.opt.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
end

vim.g.mapleader = " "
vim.g.copilot_assume_mapped = true

-- Plugins
----------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Themes
    -- Alternatives:
    -- - rebelot/kanagawa.nvim
    -- - andersevenrud/nordic.nvim
    -- - arcticicestudio/nord-vim
    {
        "Mofiqul/vscode.nvim",
        config = function()
            vim.cmd.colorscheme("vscode")
            vim.o.background = 'light'
        end
    },

    -- Git
    "tpope/vim-fugitive",
    "airblade/vim-gitgutter",

    -- Language and Framework Support
    {
        "neovim/nvim-lspconfig",
        dependencies = { "hrsh7th/cmp-nvim-lsp" },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local lspconfig = require("lspconfig")
            local servers = { "purescriptls", "eslint", "astro" }
            lspconfig.tsserver.setup({
                capabilities = capabilities,
                init_options = {
                    maxTsServerMemory = 32000
                }

            })
            for _, lsp in ipairs(servers) do
                lspconfig[lsp].setup({
                    -- on_attach = my_custom_on_attach,
                    capabilities = capabilities,
                })
            end
        end,
    },
    "purescript-contrib/purescript-vim",
    {
        "hrsh7th/nvim-cmp",
        config = function()
            local cmp = require("cmp")
            local cmp_mapping = cmp.mapping.preset.insert({
                ["<C-u>"] = cmp.mapping.scroll_docs(-4), -- Up
                ["<C-d>"] = cmp.mapping.scroll_docs(4), -- Down
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<CR>"] = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = true,
                }),
                ["<Down>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<Up>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    fallback()
                end),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    fallback()
                end),
            })
            cmp.setup({ mapping = cmp_mapping, sources = { { name = "nvim_lsp" } } })
        end,
    },
    "hrsh7th/cmp-nvim-lsp",
    {
        "wuelnerdotexe/vim-astro",
        config = function()
            vim.g.astro_typescript = "enable"
        end,
    },
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "mxsdev/nvim-dap-vscode-js",
            {
                "microsoft/vscode-js-debug",
                version = "1.x",
                build = "npm ci --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out"
            },
            { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } }
        },
        config = function()
            require("dap-vscode-js").setup({
                -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
                debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug", -- Path to vscode-js-debug installation.
                -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
                adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
                -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
                -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
                -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
            })
            for _, language in ipairs({ "typescript", "javascript" }) do
                require("dap").configurations[language] = {
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Launch file",
                        program = "${file}",
                        cwd = "${workspaceFolder}/fpa-node",
                    },
                    {
                        type = "pwa-node",
                        request = "attach",
                        name = "Attach",
                        processId = require("dap.utils").pick_process,
                        cwd = "${workspaceFolder}/fpa-node",
                    },
                    {
                        type = "pwa-node",
                        request = "launch",
                        name = "Debug XSJSLib Test",
                        runtimeExecutable = "npm",
                        runtimeArgs = {
                          "run",
                          "test:debug",
                        },
                        cwd = "${workspaceFolder}/fpa-node",
                        console = "integratedTerminal",
                        internalConsoleOptions = "neverOpen",
                    }
                }
            end
            local dap = require("dap")
            local dapui = require("dapui")
            dapui.setup()
            vim.keymap.set("n", "<leader>dc", dap.continue)
            vim.keymap.set("n", "<leader>dn", dap.step_over)
            vim.keymap.set("n", "<leader>di", dap.step_into)
            vim.keymap.set("n", "<leader>do", dap.step_out)
            vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint)
            vim.keymap.set("n", "<leader>df", dap.focus_frame)
            vim.keymap.set("n", "<leader>dd", dap.disconnect)
            vim.keymap.set("n", "<leader>dt", dap.terminate)
            vim.keymap.set("n", "<leader>du", dapui.toggle)
        end,
    },

    -- Tooling
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-live-grep-args.nvim" ,
                version = "^1.0.0"
            },
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            telescope.setup({
                defaults = {
                    layout_strategy = "vertical",
                    layout_config = {
                        width = 0.9999,
                        height = 0.9999,
                        preview_height = 0.7
                    },
                    mappings = {
                        i = {
                            ["<C-l>"] = actions.cycle_history_next,
                            ["<C-h>"] = actions.cycle_history_prev
                        }
                    }
                },
                pickers = {
                    git_status = {
                        initial_mode = "normal",
                    },
                    buffers = {
                        initial_mode = "normal",
                    },
                    buffers = {
                        sort_lastused = true,
                        theme = "dropdown",
                        previewer = false,
                        initial_mode = "normal"
                    },
                    find_files = {
                        find_command = { "rg", "--files", "--hidden", "--follow", "--no-ignore-vcs", "--glob", "!.git", "--glob", "!node_modules", "--glob", "!webpack/build*" }
                    }
                }
            })

            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
            vim.keymap.set("n", "<leader>fg", ":lua require(\"telescope\").extensions.live_grep_args.live_grep_args()<CR>")
            vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
            vim.keymap.set("n", "<leader>gs", builtin.git_status, {})
            telescope.load_extension("live_grep_args")
        end
    },

    -- Others
    "lambdalisue/suda.vim",
    "github/copilot.vim"
})

-- Key Maps
----------------------------------------------------------------------------
vim.keymap.set("n", "<SPACE>", "<NOP>")
vim.keymap.set("n", "<C-h>", ":winc h<CR>")
vim.keymap.set("n", "<C-j>", ":winc j<CR>")
vim.keymap.set("n", "<C-k>", ":winc k<CR>")
vim.keymap.set("n", "<C-l>", ":winc l<CR>")
vim.keymap.set("t", "<ESC>", "<C-\\><C-n><CR>")
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set("n", "<leader>s", ":update<CR>")
vim.keymap.set("n", "<leader>g", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>n", ":cnext<CR>")
vim.keymap.set("n", "<leader>p", ":cprev<CR>")
vim.keymap.set("n", "gb", ":ls<CR>:b<Space>")
vim.keymap.set("n", "<space>fmt", ":!npx prettier --write --config-precedence=file-override --print-width 160 --tab-width 4 --no-bracket-spacing %<CR>")

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set("n", "<space>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
        vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    end,
})

-- File Associations
----------------------------------------------------------------------------
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = "*.xsjslib",
    callback = function(ev)
        vim.bo[ev.buf].filetype = "javascript"
    end,
})

