# ozsh - Oh My Zsh Component

Installs and configures Oh My Zsh with the Spaceship prompt, autosuggestions,
syntax highlighting, and fzf.

## What it does

- Installs zsh (via apt/dnf/yum/pacman/brew) if missing.
- Installs Oh My Zsh if `$ZSH` (default `~/.oh-my-zsh`) is absent.
- Installs fzf into `~/.fzf` if missing.
- Installs `zsh-autosuggestions`, `zsh-syntax-highlighting`, and the Spaceship
  theme into `$ZSH_CUSTOM` (`~/.oh-my-zsh/custom/`).
- Replaces `~/.zshrc` (backing up any existing one) and seeds `~/.zshrc.local`.
- Sets zsh as the login shell via `chsh`.

## Commands

```bash
bash ozsh/scripts/install.sh     # install / update
bash ozsh/scripts/remove.sh      # remove (interactive prompts)
```

Both honour `SETUP_QUIET=1` to suppress status output.

## Files

- `dotfiles/.zshrc` - managed main config, copied to `~/.zshrc`.
- `dotfiles/.zshrc.local` - copied to `~/.zshrc.local` only if it does not
  already exist; this is the only file safe to edit for personal customizations.

## Notes

- Third-party plugins/themes are installed under `$ZSH_CUSTOM`, never inside the
  Oh My Zsh git checkout. Cloning into `$ZSH/plugins` or `$ZSH/themes` creates
  untracked files that make `omz update` abort. The installer migrates any
  legacy clones out of the checkout automatically.
- `~/.zshrc` sets `ZSH="${ZSH:-$HOME/.oh-my-zsh}"`, so an existing `ZSH`
  environment variable is respected.
