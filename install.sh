export DOTFILES=$(pwd)
sudo visudo
brew install git
brew install mysql@5.7
brew install redis 
brew install unrar
brew install pkg-config
brew install imagemagick
brew install postgresql 
brew install ag
brew install zsh
brew install zlib
brew install tig 
brew install mecab 

brew install mecab mecab-ipdic
brew install mecab-ipadic 
brew install ctags
brew install pythonx 
brew install greenlet
brew install macvim 
brew install tmux
brew install vtop 
brew install tpm 
brew install tree
brew install tmux 

git submodule update --init --recursive

sh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

ln -s ./zsh/zshrc ~/.zshrc

source ./others/powerline/install.sh
