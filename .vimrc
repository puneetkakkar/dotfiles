"====================Vundle================"
    set nocompatible              " be iMproved, required
    filetype off                  " required

    " set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()
    " alternatively, pass a path where Vundle should install plugins
    "call vundle#begin('~/some/path/here')

    " let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'

    Plugin 'Valloric/YouCompleteMe'

    Plugin 'Yggdroot/indentLine'
    

    " All of your Plugins must be added before the following line
    call vundle#end()            " required
    filetype plugin indent on    " required
    " To ignore plugin indent changes, instead use:
    "filetype plugin on
    "
    " Brief help
    " :PluginList       - lists configured plugins
    " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
    " :PluginSearch foo - searches for foo; append `!` to refresh local cache
    " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
    "
    " see :h vundle for more details or wiki for FAQ

    let g:ycm_global_ycm_extra_conf = '/home/puneet/.vim/YCM/ycm_extra_conf.py'
"====================Pathogen=============="
    execute pathogen#infect()
"================Syntastic================="
"   set statusline+=%#warningmsg#
"   set statusline+=%{SyntasticStatuslineFlag()}
"   set statusline+=%*

   let g:syntastic_always_populate_loc_list = 1
   let g:syntastic_auto_loc_list = 1
   let g:syntastic_check_on_open = 1
   let g:syntastic_check_on_wq = 0
"==================   Theme    ============"
    set t_Co=256
    colorscheme atom-dark-256
    set background=dark
    syntax on
"================Spaces and Tabs==========="
    set tabstop=4
    set softtabstop=4
    set expandtab
    set shiftwidth=4
"==================UI Config==============="
    set number
    set showcmd
    set cursorline
    filetype indent on
    set showmatch
    set laststatus=2
"==================Searching================"
    set incsearch
    set hlsearch
    :hi Search ctermbg=3 ctermfg=8
"==================Movement================="
    set ttyfast
    nnoremap B ^
    nnoremap E $
    set backspace=indent,eol,start
    nnoremap <C-L> <C-W><C-L>
    nnoremap <C-K> <C-W><C-K>
    nnoremap <C-J> <C-W><C-J>
    nnoremap <C-H> <C-W><C-H>
"==============Leader Shortcuts============="
    let mapleader=" "
    inoremap jk <esc>
    nnoremap <leader>ev :vsp $MYVIMRC<CR>
    nnoremap <leader>sv :source $MYVIMRC<CR>
    nnoremap <leader>s :update<CR>
"====================NERDTree=============="
    nnoremap <leader>d :NERDTree<CR>
"    let g:NERDTreeDirArrowExpandable="+"
"    let g:NERDTreeDirArrowCollapsible="~"
"===================Syntastic=============="
    let g:syntastic_java_checker = ['javac']
"====================Powerline============="
set rtp+=$HOME/.local/lib/python3/site-packages/powerline/bindings/vim/

" Always show statusline
set laststatus=2
