# git - Git Component

Installs git and deploys a managed global Git configuration with sensible
defaults, aliases, and a global ignore file.

## What it does

- Installs git (via `pkg_install`) if missing.
- Replaces `~/.gitconfig` (backing up any existing one).
- Installs `~/.gitignore_global`.
- Seeds `~/.gitconfig.local` for your identity and overrides; prompts for
  `user.name`/`user.email` on an interactive fresh install.

## Commands

```bash
bash git/scripts/install.sh          # install / update
bash git/scripts/remove.sh           # restore/remove (interactive prompts)
bash git/scripts/doctor.sh           # status report
```

All honour `SETUP_QUIET=1` and `SETUP_DRY_RUN=1`.

## Files

- `dotfiles/.gitconfig` - managed config, copied to `~/.gitconfig`. It includes
  `~/.gitconfig.local` last so personal settings win.
- `dotfiles/.gitconfig.local` - copied to `~/.gitconfig.local` only if absent.
- `dotfiles/.gitignore_global` - copied to `~/.gitignore_global`, referenced by
  `core.excludesfile`.

## Notes

- Git itself is never uninstalled by `remove.sh`.
- `~/.gitconfig.local` is kept unless you accept the backup-and-remove prompt.
