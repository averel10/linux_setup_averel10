# AGENTS.md

Bash-based Linux setup repo. A top-level component CLI (`install.sh`) dispatches to per-component install/remove scripts. The only tooling is a GitHub Actions shellcheck job; there are no tests or build.

## Commands

```bash
./install.sh                 # interactive menu
./install.sh list            # list components
./install.sh install ozsh    # install one component (all)
./install.sh -q install all  # --quiet suppresses status output
./install.sh remove ozsh
```

Component scripts can be run directly: `bash ozsh/scripts/install.sh`, `bash ozsh/scripts/remove.sh`. They honour `SETUP_QUIET=1`.

## Verifying changes

Run shellcheck (CI uses the preinstalled version, pass `-x`); scripts must be clean:

```bash
shellcheck -x install.sh ozsh/scripts/install.sh ozsh/scripts/remove.sh
```

Test scripts against a throwaway HOME (`HOME=$(mktemp -d)`) so you never touch the
real `~/.oh-my-zsh` or `~/.zshrc`. Note that `$ZSH`/`$ZSH_CUSTOM` are inherited
from the environment, so unset them (`env -u ZSH -u ZSH_CUSTOM`) for isolation.

## Adding a component

Registering a component touches these places in `install.sh`, which must stay in sync:
1. `COMPONENT_ORDER` array (menu numbering follows this order)
2. `COMPONENTS` associative array (description)
3. `install_component()` case statement
4. `remove_component()` case statement

Then create `<component>/scripts/{install.sh,remove.sh}`, `<component>/dotfiles/`, and `<component>/README.md`.

## Conventions

- Yes/no prompts must read a full line via the `ask_yes_no` helper. Do **not** use `read -n 1`: it leaves the trailing newline for the next prompt to consume.
- Use the `say` helper for status output so `--quiet`/`SETUP_QUIET=1` works.
- Top-level `install.sh` uses `set -u` and propagates component exit codes; it deliberately does not use `set -e`. `ozsh/scripts/install.sh` uses `set -euo pipefail`.

## Gotchas

- Installing `ozsh` overwrites `~/.zshrc` (backing it up to `~/.zshrc.backup.<timestamp>` first) and runs `sudo chsh -s` to change the login shell. `~/.zshrc.local` is the only user-editable file preserved across installs.
- Third-party plugins/themes (zsh-autosuggestions, zsh-syntax-highlighting, spaceship) must be installed under `~/.oh-my-zsh/custom/`, never `~/.oh-my-zsh/plugins` or `~/.oh-my-zsh/themes`. Cloning into the latter creates untracked files that make `omz update` abort ("untracked working tree files would be overwritten by merge"). The install script migrates legacy clones out of the Oh My Zsh checkout; `remove.sh` only deletes copies it owns (checks `git ls-files` first).
- `remove.sh` keeps `~/.zshrc.local` if the user declines the backup. It also offers to restore bash as the login shell and to delete `~/.fzf` (only when `~/.fzf/.git` exists).
- Installer needs network access (`curl`, `git clone`) and `sudo`/root (zsh install, `chsh`).
