# Load .ENV
if [ -f ~/.env ]; then
  source ~/.env
fi

# ---------------------------------------------------------
# Oh-My-Zsh
# ---------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Disabled — Starship handles the prompt

plugins=(
  git
  zsh-nvm
  zsh-autosuggestions
  zsh-syntax-highlighting
)

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Force emacs keybindings for line editing (zsh auto-enables vi mode
# when VISUAL/EDITOR contains "vi", which breaks Cmd+key shortcuts)
bindkey -e

# NVM fallback (in case zsh-nvm plugin is not loaded)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---------------------------------------------------------
# Prompt & Editors
# ---------------------------------------------------------
eval "$(starship init zsh)"
export GIT_EDITOR=vim
export VISUAL=vim

# ---------------------------------------------------------
# Aliases
# ---------------------------------------------------------

# File listing (eza)
alias ls='eza --color=auto --icons'
alias ll='eza -alF'
alias la='eza -a'
alias l='eza -F'
alias lt='eza --tree'

# Grep
alias grep='grep --color=auto'
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# System
alias df='df -h'
alias du='du -h'
alias path='echo -e ${PATH//:/\\n}'

# ---------------------------------------------------------
# Dotfiles & Scripts
# ---------------------------------------------------------
if [[ -d "/workspaces/.codespaces/.persistedshare/dotfiles/" ]]; then
  export DOTFILES_ROOT="/workspaces/.codespaces/.persistedshare/dotfiles"
else
  export DOTFILES_ROOT="$HOME/.dotfiles"
fi

export PATH="$DOTFILES_ROOT/scripts:$PATH"

alias rtid='run-tests-in-directory'
alias rc='rubocop-changed'
alias f='find-in-changed'
alias squash='merge-squash'
alias reload='source ~/.zshrc'

# ---------------------------------------------------------
# fzf
# ---------------------------------------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Use fd for fzf if available (respects .gitignore)
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ---------------------------------------------------------
# Functions
# ---------------------------------------------------------

# Create and connect to a new Codespace
new_cs() {
  local codespace_id
  codespace_id="$(gh cs create -R github/github -b master --devcontainer-path .devcontainer/devcontainer.json -m largePremiumLinux | tail -1)"
  gh cs code -c "$codespace_id"
  echo "Started Codespace $codespace_id"
}
alias new-cs='new_cs'

# Create a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }
