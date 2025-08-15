#!/bin/sh

zshrc() {
  echo "==========================================================="
  echo "                 cloning zsh-zsh-nvm                       "
  echo "-----------------------------------------------------------"
  git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-nvm
  echo "==========================================================="
  echo "                  Import zshrc                             "
  echo "----------------------------------------------------------"
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
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
    sudo chsh -s /bin/zsh $(whoami)
    return
  else
    echo "Starship is already installed"
  fi

}

install_nvm() {
  echo "==========================================================="
  echo "              Installing NVM                               "
  echo "-----------------------------------------------------------"
  # Only install if not already installed
  if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    echo "NVM has been installed"
  else
    echo "NVM is already installed"
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
install_nvm
configure_starship
zshrc
packages

# Setup auto tracking of branches
git config --global --add --bool push.autoSetupRemote true
