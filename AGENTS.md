# AGENTS.md

Bash-based Linux setup repo. `install.sh` is an auto-discovering component CLI that dispatches to `<component>/scripts/{install,remove}.sh`. Shared helpers live in `lib/common.sh`. CI runs shellcheck plus a hermetic test suite; there are no other build steps.

## Commands

```bash
./install.sh                 # interactive menu
./install.sh list            # list components
./install.sh doctor          # per-component status report
./install.sh install ozsh    # install one component
./install.sh install all
./install.sh --dry-run install all   # preview only
./install.sh -q remove ozsh          # --quiet
```

Component scripts can be run directly: `bash ozsh/scripts/install.sh`, `bash ozsh/scripts/remove.sh`. They honour `SETUP_QUIET=1` and `SETUP_DRY_RUN=1`.

## Verifying changes

```bash
shellcheck -x -P SCRIPTDIR install.sh lib/common.sh ozsh/scripts/*.sh tests/run.sh
bash tests/run.sh
```

`-P SCRIPTDIR` is required: component scripts source the lib via a path relative to themselves. `tests/run.sh` is hermetic (throwaway `HOME`, stub `zsh`, no network); extend it rather than testing by hand. For manual checks, use `HOME=$(mktemp -d)` and `env -u ZSH -u ZSH_CUSTOM` so you never touch the real `~/.oh-my-zsh` or `~/.zshrc`.

## Adding a component

No changes to `install.sh` are needed; components are discovered by `<dir>/component.conf`:

1. Create `<name>/component.conf` setting `COMPONENT_DESCRIPTION` and `COMPONENT_ORDER` (lower = earlier in the menu).
2. Add `scripts/install.sh` and `scripts/remove.sh`, sourcing `lib/common.sh`.
3. Add `dotfiles/`, an optional `scripts/doctor.sh`, and `README.md`.

## Conventions

- Source `lib/common.sh` and use `say`/`warn`/`error`/`die`, `ask_yes_no`, `run_root`, `pkg_update`/`pkg_install`, and `backup_path`. Do not re-implement colors, prompts, or package-manager detection in a component.
- Yes/no prompts must read a full line via `ask_yes_no`. Do **not** use `read -n 1`: it leaves the trailing newline for the next prompt to consume.
- Strip hardcoded distro logic: use `pkg_*` helpers so apt/dnf/yum/pacman/brew all work.
- Top-level `install.sh` uses `set -u` and propagates component exit codes; it deliberately does not use `set -e`. Component scripts use `set -euo pipefail` (or `set -u` when they rely on guarded commands).
- Every component script must exit non-zero on failure so `install.sh` reports it.

## Gotchas

- Installing `ozsh` overwrites `~/.zshrc` (backing it up to `~/.zshrc.backup.<timestamp>` first) and runs `sudo chsh -s` to change the login shell. `~/.zshrc.local` is the only user-editable file preserved across installs.
- Third-party Oh My Zsh plugins/themes must live under `~/.oh-my-zsh/custom/`, never `~/.oh-my-zsh/plugins` or `/themes`. Cloning into the latter creates untracked files that make `omz update` abort ("untracked working tree files would be overwritten by merge"). `install.sh` migrates legacy clones out; `remove.sh` only deletes copies it owns (checks `git ls-files` first).
- `remove.sh` keeps `~/.zshrc.local` if the user declines the backup. It also offers to restore bash as the login shell and to delete `~/.fzf` (only when `~/.fzf/.git` exists).
- `--dry-run` is implemented per component: the script must check `SETUP_DRY_RUN` and exit before mutating anything.
- Installer needs network access (`curl`, `git clone`) and `sudo`/root (zsh install, `chsh`).
