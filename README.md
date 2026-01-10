# Linux Setup - Reproducible Configuration Repository

A modular repository for reproducible Linux setups. Start with Oh My Zsh and extend with additional components as needed.

## Overview

This repository contains installable components for setting up a consistent development environment across different machines.

### Current Components

- **[ozsh](ozsh/)** - Oh My Zsh with Spaceship prompt and plugins
  - Automatic shell change to zsh
  - Syntax highlighting & auto-suggestions
  - Git integration
  - Docker/Kubernetes support

### Future Components

More components can be added to this repository (e.g., vim config, tmux, development tools, etc.).

## Quick Start

### Interactive Mode (Recommended)

```bash
./install.sh
```

This opens a main menu where you can choose to install, remove, or list components.

### Command Line Mode

Install Oh My Zsh:
```bash
./install.sh install ozsh
```

Install all components:
```bash
./install.sh install all
```

Remove Oh My Zsh:
```bash
./install.sh remove ozsh
```

List available components:
```bash
./install.sh list
```

Show help:
```bash
./install.sh help
```

## Repository Structure

```
linux_setup_averel10/
├── install.sh              # Main installer with component menu
├── README.md               # This file
│
├── ozsh/                   # Oh My Zsh component
│   ├── dotfiles/
│   │   ├── .zshrc          # Main configuration
│   │   └── .zshrc.local    # Template for customizations
│   ├── scripts/
│   │   ├── install.sh      # Component installer
│   │   └── remove.sh       # Component remover
│   └── README.md           # Component documentation
│
├── dotfiles/               # (legacy - being phased out)
└── scripts/                # (legacy - being phased out)
```

## Components

### Oh My Zsh (ozsh)

Beautiful shell configuration with:
- Spaceship prompt theme
- Syntax highlighting & auto-suggestions
- Git aliases and enhancements
- Docker/Kubernetes support
- Customizable via `~/.zshrc.local`

**[Learn more →](ozsh/README.md)**

## How to Use Each Component

Each component has its own README with detailed instructions:

1. [Oh My Zsh Setup](ozsh/README.md)

## Installation Options

### Interactive Menu

```bash
./install.sh
```

Main menu with options to:
- Install components
- Remove components
- List components
- Show help

### Command Line Arguments

**Install Commands:**
```bash
./install.sh install              # Interactive menu
./install.sh install ozsh         # Install specific component
./install.sh install all          # Install all components
```

**Remove Commands:**
```bash
./install.sh remove               # Interactive menu
./install.sh remove ozsh          # Remove specific component
./install.sh remove all           # Remove all components
```

**Utility Commands:**
```bash
./install.sh list                 # List available components
./install.sh help                 # Show help and usage
./install.sh -h                   # Alternative help
./install.sh --help               # Alternative help
```

## Personalization

Most components support local customizations that persist across updates:

- **Oh My Zsh**: Edit `~/.zshrc.local`

These files won't be overwritten when you pull updates and reinstall.

## Updating Configuration

To get the latest updates from the repository:

```bash
git pull
bash install.sh
# or bash <component>/scripts/install.sh
```

Your personal customizations will be preserved.

## Removal

Each component can be safely removed:

```bash
# Remove Oh My Zsh
./install.sh remove ozsh

# Remove all components
./install.sh remove all

# Remove with interactive menu
./install.sh remove
```

Removal scripts will optionally backup your configurations before removing.

## Prerequisites

Depends on the component, but generally:
- `bash` or `zsh` shell
- `git`
- `curl` (for remote installations)

## Platform Support

Tested on:
- Ubuntu 20.04+
- Debian 10+
- Fedora 33+
- macOS 10.15+

## Contributing

To add a new component:

1. Create a new folder: `<component-name>/`
2. Add `dotfiles/` and `scripts/` subdirectories
3. Create `install.sh` and `remove.sh` scripts
4. Add `README.md` with component documentation
5. Update the main `install.sh` to include the new component

## License

Feel free to use and modify as needed.
