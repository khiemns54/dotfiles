export DOTFILES=$(pwd)
sudo visudo

git submodule update --init --recursive

sh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

ln -s ./zsh/zshrc ~/.zshrc

source ./others/powerline/install.sh
