# AGENTS.md

Bash-based Linux setup repo. A top-level component CLI (`install.sh`) dispatches to per-component install/remove scripts. No test, lint, build, or CI tooling exists.

## Commands

```bash
./install.sh                 # interactive menu
./install.sh list            # list components
./install.sh install ozsh    # install one component
./install.sh install all
./install.sh remove ozsh
./install.sh remove all
```

Component scripts can be run directly: `bash ozsh/scripts/install.sh`, `bash ozsh/scripts/remove.sh`.

## Adding a component

Registering a component touches three places in `install.sh`, all of which must stay in sync:
1. `COMPONENTS` associative array (line ~15)
2. `install_component()` case statement
3. `remove_component()` case statement

Then create `<component>/scripts/{install.sh,remove.sh}` and `<component>/dotfiles/`.

## Gotchas

- Installing `ozsh` overwrites `~/.zshrc` (backing it up to `~/.zshrc.backup.<timestamp>` first) and runs `sudo chsh -s` to change the login shell. `~/.zshrc.local` is the only user-editable file preserved across installs.
- `ozsh/scripts/remove.sh` unconditionally deletes `~/.zshrc.local` after offering a backup.
- Installer needs network access (`curl`, `git clone`) and `sudo`.
- `ozsh/scripts/install.sh` uses `set -e`; the top-level `install.sh` does not.
- README/QUICKREF reference `ozsh/README.md` and legacy `dotfiles/`/`scripts/` dirs that do not exist. Trust the actual files, not the docs.
