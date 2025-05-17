#!/bin/sh

zshrc() {
  echo "==========================================================="
  echo "                 cloning zsh-zsh-nvm                       "
  echo "-----------------------------------------------------------"
  git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-nvm
  echo "==========================================================="
  echo "                  Import zshrc                             "
  echo "-----------------------------------------------------------"
  cat .zshrc >$HOME/.zshrc
  echo "==========================================================="
  echo "              Setup Starship config                        "
  echo "-----------------------------------------------------------"
  mkdir -p $HOME/.config
  cat starship.toml >$HOME/.config/starship.toml
}

install_starship() {
  echo "==========================================================="
  echo "              Installing Starship                          "
  echo "-----------------------------------------------------------"
  # Use the official installer script with -y flag for non-interactive install
  curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_fabulous() {
  echo "==========================================================="
  echo "               Installing fabulous                         "
  echo "-----------------------------------------------------------"

  # Install fabulous using pip with --yes flag for non-interactive install
  if
    command -v pip3 &
    >/dev/null
  then
    pip3 install --yes fabulous
  elif
    command -v pip &
    >/dev/null
  then
    pip install --yes fabulous
  else
    echo "Could not install fabulous: pip not found"
    echo "Please install pip and try again"
  fi
}

packages() {
  echo "==========================================================="
  echo "               Installing packages                         "
  echo "-----------------------------------------------------------"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew install exa
  elif [ -x "$(command -v apt)" ]; then
    # Debian/Ubuntu
    sudo apt-get install -y exa
  elif [ -x "$(command -v dnf)" ]; then
    # Fedora
    sudo dnf install -y exa
  elif [ -x "$(command -v pacman)" ]; then
    # Arch
    sudo pacman -S --noconfirm exa
  else
    echo "Could not install packages: Unsupported package manager"
  fi
}

# Install components
install_starship
install_fabulous
zshrc
packages

# Setup auto tracking of branches
git config --global --add --bool push.autoSetupRemote true
