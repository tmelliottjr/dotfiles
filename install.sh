#!/usr/bin/env bash
set -euo pipefail

# ===========================================================
#  Dotfiles Installer
#  Works on macOS (Homebrew) and Linux/Codespaces (apt)
# ===========================================================

# --- Helpers ------------------------------------------------
info()    { printf "\033[0;34m[INFO]\033[0m  %s\n" "$1"; }
ok()      { printf "\033[0;32m[OK]\033[0m    %s\n" "$1"; }
warn()    { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }
err()     { printf "\033[0;31m[ERR]\033[0m   %s\n" "$1"; }

# --- Environment Detection ---------------------------------
if [[ -d "/workspaces/.codespaces/.persistedshare/dotfiles/" ]]; then
  DOTFILES_ROOT="/workspaces/.codespaces/.persistedshare/dotfiles"
  IS_CODESPACE=true
else
  DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
  IS_CODESPACE=false
fi
export DOTFILES_ROOT

info "Dotfiles:  $DOTFILES_ROOT"
info "OS:        $OSTYPE"
info "Codespace: $IS_CODESPACE"
echo ""

# --- Oh-My-Zsh ---------------------------------------------
install_omz() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "Oh-My-Zsh already installed"
    # Ensure current user owns the directory (may be root from prior install)
    if [ ! -w "$HOME/.oh-my-zsh/custom" ]; then
      info "Fixing Oh-My-Zsh directory permissions..."
      sudo chown -R "$(id -u):$(id -g)" "$HOME/.oh-my-zsh"
    fi
  else
    info "Installing Oh-My-Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh-My-Zsh installed"
  fi
}

# --- OMZ Plugins --------------------------------------------
install_omz_plugins() {
  local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  local -a names urls
  names=(zsh-nvm            zsh-autosuggestions                   zsh-syntax-highlighting)
  urls=(
    "https://github.com/lukechilds/zsh-nvm"
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
  )

  for i in "${!names[@]}"; do
    local dir="$custom_dir/plugins/${names[$i]}"
    if [ -d "$dir" ]; then
      ok "${names[$i]} already installed"
    else
      info "Cloning ${names[$i]}..."
      git clone --depth 1 "${urls[$i]}" "$dir"
      ok "${names[$i]} installed"
    fi
  done
}

# --- Starship -----------------------------------------------
install_starship() {
  if command -v starship >/dev/null 2>&1; then
    ok "Starship already installed"
  else
    info "Installing Starship..."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
    ok "Starship installed"
  fi
}

# --- NVM ----------------------------------------------------
install_nvm() {
  if [ -d "$HOME/.nvm" ]; then
    ok "NVM already installed"
  else
    info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    ok "NVM installed"
  fi
}

# --- fzf ----------------------------------------------------
install_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    ok "fzf already installed"
  else
    info "Installing fzf..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install fzf
      "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    else
      sudo apt-get update -qq
      sudo apt-get install -y -qq fzf
    fi
    ok "fzf installed"
  fi
}

# --- eza ----------------------------------------------------
install_eza() {
  if command -v eza >/dev/null 2>&1; then
    ok "eza already installed"
  else
    info "Installing eza..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      brew install eza
    elif command -v apt-get >/dev/null 2>&1; then
      sudo mkdir -p /etc/apt/keyrings
      wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list
      sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
      sudo apt-get update -qq
      sudo apt-get install -y -qq eza
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y eza
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm eza
    else
      warn "Could not install eza — unsupported package manager"
      warn "Install manually: https://eza.rocks/"
    fi
    ok "eza installed"
  fi
}

# --- Symlinks -----------------------------------------------
create_symlinks() {
  info "Creating symlinks..."
  mkdir -p "$HOME/.config"

  ln -sf "$DOTFILES_ROOT/.zshrc"       "$HOME/.zshrc"
  ln -sf "$DOTFILES_ROOT/starship.toml" "$HOME/.config/starship.toml"
  ln -sf "$DOTFILES_ROOT/.gitconfig"   "$HOME/.gitconfig"

  ok "Linked .zshrc → ~/.zshrc"
  ok "Linked starship.toml → ~/.config/starship.toml"
  ok "Linked .gitconfig → ~/.gitconfig"
}

# --- Scripts ------------------------------------------------
setup_scripts() {
  if [ -d "$DOTFILES_ROOT/scripts" ]; then
    chmod +x "$DOTFILES_ROOT/scripts"/*
    ok "Scripts are executable"
  else
    warn "No scripts directory found"
  fi
}

# --- Default Shell ------------------------------------------
set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [ "$SHELL" = "$zsh_path" ]; then
    ok "zsh is already the default shell"
  else
    info "Setting zsh as default shell..."
    chsh -s "$zsh_path" 2>/dev/null || sudo chsh -s "$zsh_path" "$(whoami)"
    ok "Default shell set to zsh"
  fi
}

# --- macOS extras (Brewfile) --------------------------------
install_brewfile() {
  if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
    if [ -f "$DOTFILES_ROOT/Brewfile" ]; then
      info "Running brew bundle..."
      brew bundle --file="$DOTFILES_ROOT/Brewfile"
      ok "Brewfile packages installed"
    fi
  fi
}

# --- Main ---------------------------------------------------
main() {
  echo "==========================================================="
  echo "                  Installing dotfiles                      "
  echo "==========================================================="
  echo ""

  install_omz
  install_omz_plugins
  install_starship
  install_nvm
  install_fzf
  install_eza
  install_brewfile
  create_symlinks
  setup_scripts
  set_default_shell

  echo ""
  echo "==========================================================="
  echo "               Installation complete! 🎉                  "
  echo "==========================================================="
  echo "Restart your terminal or run:  source ~/.zshrc"
}

main "$@"