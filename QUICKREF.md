# Quick Reference - Linux Setup CLI

## Common Commands

```bash
# Show help
./install.sh help

# List available components
./install.sh list

# Interactive main menu
./install.sh

# Install Oh My Zsh (interactive)
./install.sh install

# Install Oh My Zsh (direct)
./install.sh install ozsh

# Install all components
./install.sh install all

# Remove Oh My Zsh (interactive)
./install.sh remove

# Remove Oh My Zsh (direct)
./install.sh remove ozsh

# Remove all components
./install.sh remove all
```

## Menu Examples

### Main Menu
```
Select an action:
  1 - Install components
  2 - Remove components
  3 - List components
  4 - Show help
  q - Quit
```

### Install Menu
```
Available Components:
  1 - ozsh: Oh My Zsh - Spaceship prompt + plugins

Installation Options:
  a - install all components
  q - Quit without install

Select component(s) to install (1/a/q):
```

### Remove Menu
```
Available Components:
  1 - ozsh: Oh My Zsh - Spaceship prompt + plugins

Removal Options:
  a - remove all components
  q - Quit without remove

Select component(s) to remove (1/a/q):
```

## Environment Variables

Currently no special environment variables required, but the CLI is designed to support:
- `--quiet` flag for suppressed output (future enhancement)
- Component-specific configs in `~/.zshrc.local` (ozsh)

## Troubleshooting

If scripts aren't executable:
```bash
chmod +x install.sh
chmod +x ozsh/scripts/*.sh
```

If colors aren't working:
- The script uses standard ANSI color codes
- Most modern terminals support these automatically
