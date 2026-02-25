{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.editor.neovim;
in
{
  options.modules.editor.neovim = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.neovim = {
        enable = true;

        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        plugins = with pkgs.vimPlugins; [
          vim-sensible
          vim-surround
          vim-repeat
          vim-commentary
          vim-easymotion
          vim-highlightedyank
          vim-polyglot
          kdl-vim
          fzf-vim
          lightline-vim
          nvim-web-devicons
          nvim-tree-lua
          which-key-nvim
          pkgs.vimPlugins."catppuccin-nvim"
          {
            plugin = vim-gitgutter;
            config = ''
              let g:gitgutter_sign_added = '│'
              let g:gitgutter_sign_modified = '│'
              let g:gitgutter_sign_removed = '│'
              let g:gitgutter_sign_removed_first_line = '│'
              let g:gitgutter_sign_removed_above_and_below = '│'
              let g:gitgutter_sign_modified_removed   = '│'
            '';
          }
        ];

        extraConfig = ''
          " keymaps
          let mapleader = " "
          let maplocalleader = ","
          " Delete without replacing register
          nnoremap s "_d

          " whitespace
          set expandtab

          " indention
          set nocopyindent
          set nosmartindent

          " search
          " Pressing return clears highlighted search
          :nnoremap <CR> :nohlsearch<CR>/<BS>
          set gdefault            " search g by default
          " tab matches bracket pairs
          nnoremap <tab> %
          vnoremap <tab> %
          " Replace grep with rg
          set grepprg=rg\ --vimgrep\ --smart-case\ --follow

          " ui
          if has('termguicolors')
            set termguicolors
          endif

          lua << EOF
          require("catppuccin").setup({
            flavour = "mocha",
          })

          -- File tree
          -- Disable netrw so nvim-tree owns the file drawer
          vim.g.loaded_netrw = 1
          vim.g.loaded_netrwPlugin = 1

          require("nvim-tree").setup({
            view = { width = 35 },
            renderer = {
              group_empty = true,  -- collapse single-child dirs like src/main
              icons = { show = { git = true, file = true, folder = true } },
            },
            filters = { dotfiles = false },
          })

          -- Which-key
          local wk = require("which-key")
          wk.setup({
            icons = { mappings = false },
          })

          wk.add({
            { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
            { "<leader>f", group = "find" },
            { "<leader>ff", "<cmd>Files<cr>", desc = "Files" },
            { "<leader>fg", "<cmd>Rg<cr>", desc = "Grep" },
            { "<leader>fb", "<cmd>Buffers<cr>", desc = "Buffers" },
            { "<leader>fh", "<cmd>History<cr>", desc = "Recent files" },
            { "<leader>b", group = "buffer" },
            { "<leader>bd", "<cmd>bd<cr>", desc = "Delete buffer" },
            { "<leader>bn", "<cmd>bn<cr>", desc = "Next buffer" },
            { "<leader>bp", "<cmd>bp<cr>", desc = "Previous buffer" },
            { "<leader>w", "<cmd>w<cr>", desc = "Save" },
            { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
          })
          EOF
          colorscheme catppuccin

          set colorcolumn=80,120  " highlight columns

          " clipboard — use OSC 52 escape sequences so yanks reach the
          " system clipboard even over SSH / in tmux.
          set clipboard=unnamedplus

          " general
          au FocusLost * :wa      " save when losing focus
          set updatetime=100      " update UI elements more frequently

          " Don't use default settings for resize
          let g:vim_resize_disable_auto_mappings = 1
        '';
      };

    };
  };
}
