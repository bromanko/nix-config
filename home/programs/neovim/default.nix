{ config, pkgs, lib, ... }:

{
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;

  programs.neovim.plugins = with pkgs.vimPlugins; [
    sensible
    vim-surround
    vim-repeat
    vim-commentary
    vim-easymotion
    vim-highlightedyank
    vim-polyglot
    fzf-vim
    {
      plugin = lightline-vim;
      config = ''
        let g:lightline = {'colorscheme' : 'sonokai'}
      '';
    }
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
    {
      plugin = sonokai;
      config = ''
        if has('termguicolors')
          set termguicolors
        endif
        let g:sonokai_style = 'shusia'
        let g:sonokai_enable_italic = 1
        let g:sonokai_better_performance = 1
         " colorscheme sonokai
      '';
    }
  ];

  programs.neovim.extraConfig = ''
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

    " ui"
    set colorcolumn=80,120  " highlight columns
    set foldmethod=syntax   " enable syntax-aware folding

    " general
    au FocusLost * :wa      " save when losing focus
    set updatetime=100      " update UI elements more frequently
    " Don't use default settings for resize
    let g:vim_resize_disable_auto_mappings = 1
  '';
}
