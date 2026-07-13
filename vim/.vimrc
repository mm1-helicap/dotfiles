let mapleader = " "

noremap <leader>tn :tabnew<cr>
noremap <leader>t :tabnext<cr>
noremap <leader>tm :tabmove
noremap <leader>tc :tabclose<cr>
noremap <leader>to :tabonly<cr>
noremap <leader>] <C-]>
noremap <leader>[ <C-o>
noremap <leader>p gT
noremap <leader>o o<esc>
noremap <leader>I 0<ESC>
noremap <leader>A $<ESC>
nnoremap k gk
nnoremap N Nzz
noremap . f.l

noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>

inoremap <C-k> <Up>
inoremap <C-j> <Down>
inoremap <C-h> <Left>
inoremap <C-l> <Right>

set rnu
set scrolloff=2
set hlsearch

nnoremap <Esc> :nohlsearch<CR>

vnoremap p "_dP

xnoremap K :move '<-2<CR>gv-gv
xnoremap J :move '>+1<CR>gv-gv

noremap <leader>h <C-w>h
noremap <leader>j <C-w>j
noremap <leader>k <C-w>k
noremap <leader>l <C-w>l

noremap H ^
noremap L $
noremap * *N
noremap <leader>w 0w

noremap gb <C-o>
noremap gh {[{0w

inoremap <C-a> <Esc>ggVG
nnoremap <C-a> ggVG
vnoremap <C-a> ggVG

nnoremap > <C-w>>
nnoremap < <C-w><

set clipboard=unnamedplus
