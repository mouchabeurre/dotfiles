"if empty(glob('~/.local/share/nvim/site/autoload/plug.vim')) && executable('curl')
  "curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"endif

call plug#begin('~/.local/share/nvim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'morhetz/gruvbox'
Plug 'ap/vim-css-color'
Plug 'jiangmiao/auto-pairs'
Plug 'tomtom/tcomment_vim'
Plug 'drzel/vim-line-no-indicator'

call plug#end()

" --------------------------
" General settings
" --------------------------

syntax on
set autoindent
set tabstop=2
set shiftwidth=2
set expandtab
filetype plugin indent on
set encoding=utf-8
set fileencoding=utf-8
" show trailing whitespace
set list
set listchars=tab:▸\ ,precedes:←,extends:→,trail:•,nbsp:•,
" status bar update freq
set updatetime=100
set number
set noshowmode
set relativenumber
set signcolumn=yes
set cursorline
set cursorcolumn
" no reload on external modification
set noautoread
" keep buffer of lines above and below cursor
set scrolloff=10
" keep buffer history
set hidden

" Mapping
"
let mapleader = ","
:nnoremap <silent> <tab> :bnext<cr>
:nnoremap <silent> <S-tab> :bprevious<cr>
" switch back to last used buffer
:nnoremap <silent> <leader><tab> :b#<cr>
" remap %
nnoremap ù %
" go to next error in window
nnoremap <silent> <leader>cn :cn<cr>

" Searching
"
" disable highlight
set nohlsearch
" center on next/previous match
nnoremap n nzz
nnoremap N Nzz

" Navigation
"
" disable arrow keys
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" Colors
"
set background=dark
let g:gruvbox_italic=1
colorscheme gruvbox
"set termguicolors " 24-bit terminal
hi NonText ctermbg=none
hi Normal ctermbg=none
"hi CursorLine cterm=none term=none ctermbg=230
"hi CursorColumn cterm=none term=none ctermbg=230

" Variables
"

" Auto Commands
"
" cd in dir if is dir
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'cd' argv()[0] | endif

" --------------------------
" Plugin: vim-airline
" --------------------------

let g:airline_theme = 'gruvbox'
let g:airline_powerline_fonts = 1

let g:airline_section_x = '%{&filetype}'
let g:airline_section_y = '%#__accent_bold#%{LineNoIndicator()}%#__restore__#'
let g:airline_section_z = '%2c'
let g:airline_skip_empty_sections = 1

let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#tab_nr_type=1
"let g:airline#extensions#tabline#show_tab_nr=0
let g:airline#extensions#tabline#show_close_button=0
let g:airline#extensions#tabline#buffers_label='buffers'
let g:airline#extensions#tabline#tabs_label='tabs'

let g:airline#extensions#branch#enabled = 1
