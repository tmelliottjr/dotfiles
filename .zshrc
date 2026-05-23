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

# Find a file with tv and open it in nvim
tvim() {
  local file
  file=$(tv files)
  [[ -n "$file" ]] && nvim "$file"
}

# Pick a directory with tv, cd into it, and open nvim
tcd() {
  local dir
  dir=$(tv dirs)
  [[ -n "$dir" ]] && cd "$dir" && nvim .
}

# Search file contents with tv and open the match in nvim at the line
# Usage:
#   tgrep                     Search all files
#   tgrep -g '*.md'           Search only markdown files
#   tgrep -g '!*.md'          Exclude markdown files
#   tgrep -g '!*test*'        Exclude files matching *test*
#   tgrep -t py               Search only Python files
#   tgrep -g '*.md' -g '!README*'  Combine multiple filters
#   tgrep -i                  Interactive: prompts for filters before searching
tgrep() {
  local args=("$@") result file line
  if [[ "$1" == "-i" ]]; then
    shift
    echo -n "rg flags (e.g. -g '*.md' -g '!*test*' -t py): "
    read -r flags
    args=(${(z)flags} "$@")
  fi
  result=$(tv text --source-command "rg --line-number --color=never ${args[*]} {0}")
  [[ -n "$result" ]] || return
  file="${result%%:*}"
  line="${result#*:}"
  line="${line%%:*}"
  nvim "+${line}" "$file"
}
fpath=(~/.zsh/completions $fpath)
autoload -U compinit && compinit

eval "$(zoxide init zsh)"
