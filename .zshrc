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

# Reload shell
alias reload='source ~/.zshrc'
alias new-cs='!export CODESPACE_ID="$(gh cs create -R github/github -b master --devcontainer-path .devcontainer/devcontainer.json -m largePremiumLinux | tail -1)"; gh cs code -c $CODESPACE_ID; echo "Started Codespace $CODESPACE_ID"'

# Rubocop function with optional fix flag
rc() {
  local fix_flag=""
  if [[ "$1" == "-f" || "$1" == "--fix" ]]; then
    fix_flag="-a"
    shift
  fi
  
  # Get modified/staged files (excluding deleted) and untracked files, filter for .rb files
  {
    git diff --name-only --diff-filter=AM
    git ls-files --others --exclude-standard
  } | grep "\.rb$" | sort -u | xargs -r rubocop $fix_flag
}

# Search function
# Search within only changed files
f() {
  local search_pattern=""
  local file_filter=""
  local verbose=false
  local context_lines=""
  
  # Parse options
  while [[ $# -gt 0 ]]; do
    case $1 in
      -t|--type)
        file_filter="$2"
        shift 2
        ;;
      -v|--verbose)
        verbose=true
        shift
        ;;
      -C|--context)
        context_lines="-C $2"
        shift 2
        ;;
      -A|--after)
        context_lines="-A $2"
        shift 2
        ;;
      -B|--before)
        context_lines="-B $2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: f [options] <search_pattern> [grep_options]"
        echo "Search for a pattern in modified/staged and untracked files"
        echo ""
        echo "Options:"
        echo "  -t, --type EXT     Filter files by extension (e.g., rb, js, py)"
        echo "  -v, --verbose      Show which files are being searched"
        echo "  -C, --context N    Show N lines of context around matches"
        echo "  -A, --after N      Show N lines after matches"
        echo "  -B, --before N     Show N lines before matches"
        echo "  -h, --help         Show this help message"
        echo ""
        echo "Examples:"
        echo "  f 'function'           # Search for 'function' in all changed files"
        echo "  f -t js 'console'      # Search for 'console' only in .js files"
        echo "  f -v -C 2 'TODO'       # Search for 'TODO' with 2 lines of context"
        return 0
        ;;
      -*)
        echo "Unknown option: $1" >&2
        echo "Use 'f --help' for usage information" >&2
        return 1
        ;;
      *)
        if [[ -z "$search_pattern" ]]; then
          search_pattern="$1"
          shift
          break
        fi
        ;;
    esac
  done
  
  if [[ -z "$search_pattern" ]]; then
    echo "Usage: f [options] <search_pattern> [grep_options]"
    echo "Use 'f --help' for more information"
    return 1
  fi
  
  # Get modified/staged files (excluding deleted) and untracked files
  local files
  files=$(
    {
      git diff --name-only --diff-filter=AM
      git ls-files --others --exclude-standard
    } | sort -u
  )
  
  if [[ -z "$files" ]]; then
    echo "No changed files found."
    return 0
  fi
  
  # Apply file type filter if specified
  if [[ -n "$file_filter" ]]; then
    files=$(echo "$files" | grep "\.$file_filter$")
    if [[ -z "$files" ]]; then
      echo "No changed .$file_filter files found."
      return 0
    fi
  fi
  
  # Show files being searched if verbose
  if [[ "$verbose" == true ]]; then
    echo "Searching in files:"
    echo "$files" | sed 's/^/  /'
    echo ""
  fi
  
  # Perform the search
  echo "$files" | xargs -r grep -n --color=auto $context_lines "$@" "$search_pattern"
}