-- General Configuration
----------------------------------------------------------------------------
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
if vim.fn.has("win32") == 1 then
    vim.opt.shell = 'powershell.exe'
    vim.opt.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
    vim.opt.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
    vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
end

vim.g.mapleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Automatically source init.lua on save.
vim.cmd("autocmd! bufwritepost $MYVIMRC source $MYVIMRC")


-- Key Maps
----------------------------------------------------------------------------
function closeBuffer()
    if vim.bo.modified then
        print("Current buffer is modified!")
    else
        vim.cmd("bprevious")
        vim.cmd("bdelete #")
    end
end
vim.keymap.set("n", "<SPACE>", "<NOP>")
if vim.fn.has("mac") == 1 then
    vim.keymap.set("n", "©", ":update|bd<CR>") -- Option + g
    vim.keymap.set("n", "≈", closeBuffer)      -- Option + x
    vim.keymap.set("n", "«", ":quit<CR>")      -- Option + q
    vim.keymap.set("n", "‚", ":update<CR>")    -- Option + s
    vim.keymap.set("n", "ª", ":wincmd h<CR>")  -- Option + h
    vim.keymap.set("n", "º", ":wincmd j<CR>")  -- Option + j
    vim.keymap.set("n", "∆", ":wincmd k<CR>")  -- Option + k
    vim.keymap.set("n", "@", ":wincmd l<CR>")  -- Option + l
    vim.keymap.set("n", "µ", ":bprevious<CR>") -- Option + m
    vim.keymap.set("n", "∞", ":bnext<CR>")     -- Option + ,
    vim.keymap.set("n", "ƒ", ":Files<CR>")     -- Option + f
else
    vim.keymap.set("n", "<M-g>", ":update|bd<CR>")
    vim.keymap.set("n", "<M-x>", closeBuffer)
    vim.keymap.set("n", "<M-q>", ":quit<CR>")
    vim.keymap.set("n", "<M-s>", ":update<CR>")
    vim.keymap.set("n", "<M-h>", ":wincmd h<CR>")
    vim.keymap.set("n", "<M-j>", ":wincmd j<CR>")
    vim.keymap.set("n", "<M-k>", ":wincmd k<CR>")
    vim.keymap.set("n", "<M-l>", ":wincmd l<CR>")
    vim.keymap.set("n", "<M-m>", ":bprevious<CR>")
    vim.keymap.set("n", "<M-,>", ":bnext<CR>")
    vim.keymap.set("n", "<M-f>", ":Files<CR>")
end
vim.keymap.set("t", "<ESC>", "<C-\\><C-n><CR>")
vim.cmd("autocmd FileType fzf tnoremap <buffer> <ESC> <ESC>")
vim.cmd("autocmd FileType fzf tnoremap <C-u> <NOP>")
vim.cmd("autocmd FileType fzf tnoremap <C-i> <NOP>")


-- Plugins
----------------------------------------------------------------------------
vim.cmd([[
    augroup packer_user_config
        autocmd!
        autocmd BufWritePost init.lua source <afile> | PackerCompile
    augroup end
]])

local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

require("packer").startup(function(use)
    -- Plugin Manager
    use "wbthomason/packer.nvim"

    -- Themes
    use "rebelot/kanagawa.nvim"
    use "andersevenrud/nordic.nvim"

    -- Git
    use "tpope/vim-fugitive"
    use "airblade/vim-gitgutter"

    -- Files
    use {
        "junegunn/fzf.vim",
        requires = {"junegunn/fzf", run = ":call fzf#install()"}
    }
    use {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v2.x",
        requires = { 
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        }
    }

    -- Language and Framework Support
    use "neovim/nvim-lspconfig"
    use "purescript-contrib/purescript-vim"
    use 'wuelnerdotexe/vim-astro'

    -- Others
    use "lambdalisue/suda.vim"

    -- Packer autoload
    if packer_bootstrap then
        require("packer").sync()
    end
end)


-- LSP Setup
local lspconfig = require("lspconfig")
lspconfig.tsserver.setup {}
lspconfig.purescriptls.setup {}
lspconfig.astro.setup {}

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set("n", "<space>g", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
--vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set("n", "<space>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<space>f", function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- Astro Setup
vim.g.astro_typescript = "enable"

-- Neotree Setup
-- Unless you are still migrating, remove the deprecated commands from v1.x
vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

-- Color Scheme
----------------------------------------------------------------------------
vim.cmd("colorscheme kanagawa")
--require("nordic").colorscheme({})
