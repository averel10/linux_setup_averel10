# Quick Reference - Linux Setup CLI

## Common Commands

```bash
# Show help
./install.sh help

# List available components
./install.sh list

# Report component status
./install.sh doctor

# Preview without changing anything
./install.sh --dry-run install all

# Interactive main menu
./install.sh

# Install (interactive)
./install.sh install

# Install a component (direct)
./install.sh install ozsh

# Install the git component
./install.sh install git

# Install the GitHub CLI component
./install.sh install gh

# Install all components
./install.sh install all

# Remove (interactive)
./install.sh remove

# Remove a component (direct)
./install.sh remove ozsh

# Remove all components
./install.sh remove all

# Suppress status output
./install.sh --quiet install all
```

The interactive install/remove menu accepts one or more component numbers
(space or comma separated), `a` for all, or `q` to cancel.

## Menu Examples

### Main Menu
```
Select an action:
  1 - Install components
  2 - Remove components
  3 - List components
  4 - Show help
  5 - Doctor
  q - Quit
Choose an action (1-5/q):
```

### Install / Remove Menu
```
Available Components:

  1 - ozsh: Oh My Zsh - Spaceship prompt + plugins
  2 - git: Git config, aliases, and sensible defaults
  3 - gh: GitHub CLI - install, auth, and config

Install Options:

  a - install all components
  q - Quit without install

Select component(s) to install (numbers separated by spaces, a, q):
```

## Environment Variables

- `SETUP_QUIET=1` - suppress status output (set automatically by `--quiet`).
- `SETUP_DRY_RUN=1` - print planned actions without changing anything (set by `--dry-run`).
- `ZSH` - path to the Oh My Zsh checkout; defaults to `~/.oh-my-zsh`.
- `ZSH_CUSTOM` - custom plugins/themes directory; defaults to `$ZSH/custom`.

## Troubleshooting

If scripts aren't executable:
```bash
chmod +x install.sh
chmod +x ozsh/scripts/*.sh
```

If colors aren't working:
- The script uses standard ANSI color codes
- Most modern terminals support these automatically

If `omz update` complains about untracked files in `~/.oh-my-zsh/plugins` or
`~/.oh-my-zsh/themes`, re-run the component installer: it moves legacy
third-party clones into `~/.oh-my-zsh/custom/`.
