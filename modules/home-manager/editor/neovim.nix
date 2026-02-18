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
          sensible
          vim-surround
          vim-repeat
          vim-commentary
          vim-easymotion
          vim-highlightedyank
          vim-polyglot
          fzf-vim
          lightline-vim
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
          EOF
          colorscheme catppuccin

          set colorcolumn=80,120  " highlight columns

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
