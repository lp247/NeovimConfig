-- General Configuration
----------------------------------------------------------------------------
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
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
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
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
	{
        "rebelot/kanagawa.nvim",
        config = function()
            vim.cmd("colorscheme kanagawa")
        end
    },
	"andersevenrud/nordic.nvim",

	-- Git
	"tpope/vim-fugitive",
	"airblade/vim-gitgutter",

	-- Files
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v2.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.2",
		dependencies = { { "nvim-lua/plenary.nvim" } },
		config = function()
			local api = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", api.find_files, {})
			vim.keymap.set("n", "<leader>fg", api.live_grep, {})
			vim.keymap.set("n", "<leader>fb", api.buffers, {})
			vim.keymap.set("n", "<leader>fh", api.help_tags, {})
		end,
	},

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
		config = function()
			for _, language in ipairs({ "typescript", "javascript" }) do
				require("dap").configurations[language] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
				}
			end
			local api = require("dap")
			vim.keymap.set("n", "<leader>dc", api.continue)
			vim.keymap.set("n", "<leader>dn", api.step_over)
			vim.keymap.set("n", "<leader>di", api.step_into)
			vim.keymap.set("n", "<leader>do", api.step_out)
			vim.keymap.set("n", "<leader>dt", api.toggle_breakpoint)
		end,
	},
	{ "mxsdev/nvim-dap-vscode-js", dependencies = { "mfussenegger/nvim-dap" } },
	{
		"microsoft/vscode-js-debug",
		optional = true,
		run = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
		config = function()
			require("dap-vscode-js").setup({
				-- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
				-- debugger_path = "(runtimedir)/site/pack/packer/opt/vscode-js-debug", -- Path to vscode-js-debug installation.
				-- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
				adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
				-- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
				-- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
				-- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
			})
		end,
    },

	-- Others
	"lambdalisue/suda.vim",
	"nvim-lua/plenary.nvim",
	"github/copilot.vim"
})

-- Key Maps
----------------------------------------------------------------------------
vim.keymap.set("n", "<SPACE>", "<NOP>")
if vim.fn.has("mac") == 1 then
	vim.keymap.set("n", "ª", ":wincmd h<CR>") -- Option + h
	vim.keymap.set("n", "º", ":wincmd j<CR>") -- Option + j
	vim.keymap.set("n", "∆", ":wincmd k<CR>") -- Option + k
	vim.keymap.set("n", "@", ":wincmd l<CR>") -- Option + l
	vim.keymap.set("n", "…", ":cprevious<CR>") -- Option + .
	vim.keymap.set("n", "–", ":cnext<CR>") -- Option + -
	vim.keymap.set("i", "'", "<Plug>(copilot-next)")
	vim.keymap.set("i", "¿", "<Plug>(copilot-previous)")
else
	vim.keymap.set("n", "<M-h>", ":wincmd h<CR>")
	vim.keymap.set("n", "<M-j>", ":wincmd j<CR>")
	vim.keymap.set("n", "<M-k>", ":wincmd k<CR>")
	vim.keymap.set("n", "<M-l>", ":wincmd l<CR>")
	vim.keymap.set("n", "<M-.>", ":cprevious<CR>")
	vim.keymap.set("n", "<M-->", ":cnext<CR>")
	vim.keymap.set("i", "<M-´>", "<Plug>(copilot-next)")
	vim.keymap.set("i", "<M-ß>", "<Plug>(copilot-previous)")
end
vim.keymap.set("t", "<ESC>", "<C-\\><C-n><CR>")
vim.keymap.set("n", "<leader>e", ":Neotree float<CR>", {})
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set("n", "<leader>s", ":update<CR>")
vim.keymap.set("n", "<space>g", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

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
		vim.keymap.set("n", "<space>fmt", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
	end,
})

