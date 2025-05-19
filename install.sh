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
}

install_starship() {
  echo "==========================================================="
  echo "              Installing Starship                          "
  echo "-----------------------------------------------------------"
  # Only install if not already installed
  if
    command -v starship &
    >/dev/null
  then
    echo "Starship is already installed"
    return
  fi

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
    brew install eza
  elif [ -x "$(command -v apt)" ]; then
    # Debian/Ubuntu
    echo "Setting up eza repository for Debian/Ubuntu..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
  elif [ -x "$(command -v dnf)" ]; then
    # Fedora
    sudo dnf install -y eza
  elif [ -x "$(command -v pacman)" ]; then
    # Arch
    sudo pacman -S --noconfirm eza
  else
    echo "Attempting to install eza via cargo..."
    if
      command -v cargo &
      >/dev/null
    then
      cargo install eza
    else
      echo "Could not install eza: Unsupported package manager and cargo not found"
      echo "Please install eza manually: https://eza.rocks/"
    fi
  fi
}

# Configure starship with jetpack preset
configure_starship() {
  echo "==========================================================="
  echo "                  Setting up Starship                      "
  echo "-----------------------------------------------------------"
  mkdir -p $HOME/.config
  cat starship.toml >$HOME/.config/starship.toml
}

# Install components
install_starship
configure_starship
install_fabulous
zshrc
packages

# Setup auto tracking of branches
git config --global --add --bool push.autoSetupRemote true
