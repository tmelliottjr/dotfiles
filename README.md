# Dotfiles

Personal dotfiles for macOS and GitHub Codespaces.

## What's Included

| File / Dir        | Purpose                                       |
|-------------------|-----------------------------------------------|
| `.zshrc`          | Shell config — aliases, plugins, functions     |
| `.gitconfig`      | Git settings — editor, aliases, merge/pull     |
| `starship.toml`   | Starship prompt theme (Catppuccin Mocha)       |
| `Brewfile`        | macOS packages (via `brew bundle`)             |
| `scripts/`        | Custom CLI scripts (see below)                 |
| `copilot/`        | Copilot config — global custom instructions    |
| `install.sh`      | Installer — works on macOS and Codespaces      |

## Quick Start

```bash
# Clone
git clone https://github.com/tmelliottjr/.dotfiles.git ~/.dotfiles

# Install
cd ~/.dotfiles && ./install.sh
```

For **Codespaces**, set this repo as your dotfiles in
[GitHub settings](https://github.com/settings/codespaces) — `install.sh`
runs automatically.

## What `install.sh` Does

1. Installs [Oh-My-Zsh](https://ohmyz.sh/) + plugins (autosuggestions, syntax highlighting, zsh-nvm)
2. Installs [Starship](https://starship.rs/) prompt
3. Installs [NVM](https://github.com/nvm-sh/nvm)
4. Installs [fzf](https://github.com/junegunn/fzf) (fuzzy finder)
5. Installs [eza](https://eza.rocks/) (modern `ls`)
6. Symlinks config files to `$HOME`
7. Installs the [1up](https://github.com/github/1up) MCP server and registers it with Copilot CLI
8. Sets zsh as the default shell
9. On macOS: runs `brew bundle` for Brewfile packages

## Scripts

| Script                  | Alias    | Description                                     |
|-------------------------|----------|-------------------------------------------------|
| `run-tests-in-directory`| `rtid`   | Run Rails tests in a directory                   |
| `rubocop-changed`       | `rc`     | Run Rubocop on modified Ruby files               |
| `find-in-changed`       | `f`      | Grep through modified/staged/untracked files     |
| `merge-squash`          | `squash` | Squash all branch commits into one               |

## Machine-Specific Git Config

The versioned `.gitconfig` includes `~/.gitconfig.local`. Put
machine-specific overrides there (user name, email, signing keys):

```gitconfig
# ~/.gitconfig.local
[user]
    name = Your Name
    email = you@example.com
```

## Copilot Instructions

`copilot/copilot-instructions.md` holds personal, project-agnostic guidance for
GitHub Copilot (CLI, IDE, and cloud agent). `install.sh` symlinks it to
`~/.copilot/copilot-instructions.md`, which Copilot reads globally across every
repository. Repository-specific instructions (`AGENTS.md`,
`.github/copilot-instructions.md`) add local context and take precedence on
project-specific matters. Because it is a symlink, edits to the source apply
immediately — no reinstall needed.

### Copilot Skills

`copilot/skills/` holds personal Copilot skills, each in its own directory with a
`SKILL.md`. `install.sh` symlinks them into `~/.copilot/skills/`, where Copilot
loads them on demand when a request matches the skill's description.

| Skill                 | Triggers on                                      |
|-----------------------|--------------------------------------------------|
| `write-github-issue`  | Writing, drafting, or filing a GitHub issue      |
| `write-pull-request`  | Writing a PR title, description, or opening a PR |

### 1up MCP Server

[1up](https://github.com/github/1up) is an MCP server for discovering and
installing skills from `github/agent-config`, plus setup tools for the Datadog,
Kusto, PagerDuty, Sentry, Slack, and Splunk MCP servers.

`install.sh` adds `github.com/github/*` to `GOPRIVATE` (the repo is private), runs
`go install github.com/github/1up@latest`, and registers the binary in
`~/.copilot/mcp-config.json` under the key `oneup`. Restart Copilot CLI afterward
to pick up the server. Re-running `install.sh` upgrades it.

The key is `oneup` rather than `1up` because Copilot CLI prefixes tool names with
the server key, and some model providers reject tool names starting with a digit.

Requires Go and `jq`; the step is skipped with a warning if either is missing, and
`go install` needs access to the private `github/1up` repo.

## Key Aliases

```bash
ls, ll, la, lt    # eza variants
gs, ga, gc, gp, gl # git shortcuts
reload             # re-source .zshrc
new-cs             # spin up a github/github Codespace
```
