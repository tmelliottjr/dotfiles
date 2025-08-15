# Load .ENV

if [ -f ~/.env ]; then
  source ~/.env
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# NVM configuration
plugins=(git zsh-nvm)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# User configuration

# Initialize Starship
eval "$(starship init zsh)"

# Set default git editor
export GIT_EDITOR=vim
export VISUAL=vim

# Aliases
alias ls='eza --color=auto --icons'
alias ll='eza -alF'
alias la='eza -a'
alias l='eza -F'
alias lt='eza --tree'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# System
alias df='df -h'
alias du='du -h'
alias free='free -m'
alias path='echo -e ${PATH//:/\\n}'

# Add scripts directory to PATH
# Get the directory where this .zshrc file is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
export PATH="$DOTFILES_DIR/scripts:$PATH"

# Custom scripts
alias rtid='run-tests-in-directory'
alias rc='rubocop-changed'
alias f='find-in-changed'
alias squash='merge-squash'

# Reload shell
alias reload='source ~/.zshrc'
alias new-cs='!export CODESPACE_ID="$(gh cs create -R github/github -b master --devcontainer-path .devcontainer/devcontainer.json -m largePremiumLinux | tail -1)"; gh cs code -c $CODESPACE_ID; echo "Started Codespace $CODESPACE_ID"'