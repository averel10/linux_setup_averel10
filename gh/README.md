# gh - GitHub CLI Component

Installs the GitHub CLI (`gh`), sets up sensible defaults, adds zsh completion,
and offers to authenticate.

## What it does

- Installs `gh` via the detected package manager. If no package is available
  (e.g. older Ubuntu/Debian), it falls back to the official static release for
  Linux installed under `~/.local/opt/gh` with a symlink in `~/.local/bin`.
- Sets `git_protocol` to `https` if not already configured (never overwrites).
- Writes a `gh.zsh` completion file into the Oh My Zsh custom dir when present.
- Offers `gh auth login` on an interactive install if not authenticated.

It does not manage `~/.config/gh` directly: `gh` owns that file, including your
auth tokens.

## Commands

```bash
bash gh/scripts/install.sh           # install / update
bash gh/scripts/remove.sh            # remove (interactive prompts)
bash gh/scripts/doctor.sh            # status report
```

All honour `SETUP_QUIET=1` and `SETUP_DRY_RUN=1`.

## Removal

`remove.sh` does not uninstall the `gh` package. It offers to remove the zsh
completion file, your `~/.config/gh` (config **and auth tokens**, default no),
and a locally installed release build under `~/.local/opt/gh`.
