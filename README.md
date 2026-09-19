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
- **[git](git/)** - Global Git configuration
  - Sensible defaults, aliases, and a global ignore file
  - Personal identity kept in `~/.gitconfig.local`

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
├── install.sh              # Auto-discovering component CLI
├── lib/
│   └── common.sh           # Shared helpers (say, ask_yes_no, run_root, pkg_*)
├── tests/
│   └── run.sh              # Hermetic test suite
├── .github/workflows/      # shellcheck + tests CI
├── README.md
├── QUICKREF.md             # Command cheat sheet
├── AGENTS.md               # Notes for AI coding agents
│
├── ozsh/                   # Oh My Zsh component
│   ├── component.conf      # Description + menu order (auto-discovery)
│   ├── README.md           # Component documentation
│   ├── dotfiles/
│   │   ├── .zshrc          # Main configuration
│   │   └── .zshrc.local    # Template for customizations
│   └── scripts/
│       ├── install.sh      # Component installer
│       ├── remove.sh       # Component remover
│       └── doctor.sh       # Component status report
│
└── git/                    # Git component
    ├── component.conf
    ├── README.md
    ├── dotfiles/
    │   ├── .gitconfig
    │   ├── .gitconfig.local
    │   └── .gitignore_global
    └── scripts/
        ├── install.sh
        ├── remove.sh
        └── doctor.sh
```

## Adding a Component

Components are auto-discovered: any directory containing a `component.conf`
becomes a component, with no changes to `install.sh`. A manifest sets:

```bash
COMPONENT_DESCRIPTION="What it does"
COMPONENT_ORDER=20            # lower numbers appear first
```

The directory then provides `scripts/install.sh`, `scripts/remove.sh`, an
optional `scripts/doctor.sh`, `dotfiles/`, and a `README.md`. Component scripts
source `lib/common.sh` for shared helpers.

Oh My Zsh third-party plugins and themes are installed under
`~/.oh-my-zsh/custom/`, never inside the Oh My Zsh git checkout, so `omz update`
never fights with untracked files.

## Components

### Oh My Zsh (ozsh)

Beautiful shell configuration with:
- Spaceship prompt theme
- Syntax highlighting & auto-suggestions
- Git aliases and enhancements
- Docker/Kubernetes support
- Customizable via `~/.zshrc.local`

**[Learn more →](ozsh/README.md)**

### Git (git)

Managed global Git configuration with:
- Sensible defaults (`init.defaultBranch`, `push.autoSetupRemote`, pruning, rerere)
- Useful aliases and a global ignore file
- Identity and overrides kept in `~/.gitconfig.local`

**[Learn more →](git/README.md)**

## How to Use Each Component

Each component has its own README with detailed instructions:

1. [Oh My Zsh Setup](ozsh/README.md)
2. [Git Setup](git/README.md)

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
- Run doctor

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
./install.sh doctor               # Report the state of each component
./install.sh help                 # Show help and usage
./install.sh -h                   # Alternative help
./install.sh --help               # Alternative help
```

**Previewing changes:**
```bash
./install.sh --dry-run install all   # Print planned actions, change nothing
```

**Options:**
```bash
./install.sh -q install all       # Suppress status output
./install.sh --quiet remove ozsh  # Same as -q
```

`--quiet` suppresses status/decorative output (including component scripts) but
still prints requested data such as `list`.

The interactive install/remove menus accept one or more component numbers
(space or comma separated), `a` for all, or `q` to cancel.

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

Removal prompts before restoring `.zshrc`, deleting `~/.zshrc.local`, removing
`~/.fzf`, restoring your login shell to bash, and deleting `~/.oh-my-zsh`.
`~/.zshrc.local` is only deleted if you accept the backup; otherwise it is kept.

## Prerequisites

Depends on the component, but generally:
- `bash` or `zsh` shell
- `git`
- `curl` (for remote installations)
- `sudo` (Oh My Zsh: installs zsh and changes the login shell)

## Platform Support

Tested on:
- Ubuntu 20.04+
- Debian 10+
- Fedora 33+
- macOS 10.15+

## Contributing

To add a new component:

1. Create a folder: `<component-name>/`
2. Add a `component.conf` with `COMPONENT_DESCRIPTION` and `COMPONENT_ORDER`
3. Add `scripts/install.sh` and `scripts/remove.sh` (source `lib/common.sh`)
4. Add `dotfiles/`, an optional `scripts/doctor.sh`, and a `README.md`

No changes to `install.sh` are needed. Before committing, run:

```bash
shellcheck -x -P SCRIPTDIR install.sh lib/common.sh ozsh/scripts/*.sh tests/run.sh
bash tests/run.sh
```

## License

Feel free to use and modify as needed.
