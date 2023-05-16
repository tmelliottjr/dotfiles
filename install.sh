#!/bin/sh

zshrc() {
  echo "==========================================================="
  echo "             cloning powerlevel10k                         "
  echo "-----------------------------------------------------------"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  echo "==========================================================="
  echo "                 cloning zsh-zsh-nvm                       "
  echo "-----------------------------------------------------------"
  git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-nvm
  echo "==========================================================="
  echo "                  Import zshrc                             "
  echo "-----------------------------------------------------------"
  cat .zshrc >$HOME/.zshrc
}

packages() {
  echo "==========================================================="
  echo "                  Install Exa                              "
  echo "-----------------------------------------------------------"
  sudo apt install exa
}


packages
zshrc
sudo mv ~/.p10k.zsh.new ~/.p10k.zsh
source ~/.p10k.zsh
