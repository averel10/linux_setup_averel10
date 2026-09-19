#!/bin/bash

set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

QUIET="${SETUP_QUIET:-0}"
say() {
    [ "$QUIET" = "1" ] || echo -e "$@"
}

# Read a whole line so the trailing newline is not left for the next prompt.
# Usage: ask_yes_no "Question?" n   (defaults to no)
ask_yes_no() {
    local prompt=$1 default=${2:-n} reply
    read -r -p "$prompt " reply || true
    case $default in
        y|Y) [[ ! $reply =~ ^[Nn]$ ]] ;;
        *)   [[ $reply =~ ^[Yy]$ ]] ;;
    esac
}

# Run a command as root, using sudo only when not already root.
run_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        if ! command -v sudo >/dev/null 2>&1; then
            say "${RED}✗ This step requires root or sudo, which was not found${NC}"
            return 1
        fi
        sudo "$@"
    fi
}

# Third-party plugins/themes live in $ZSH_CUSTOM. Never delete paths tracked
# by the Oh My Zsh repo itself.
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
is_tracked() { git -C "$ZSH_DIR" ls-files --error-unmatch "$1" >/dev/null 2>&1; }

say "${BLUE}==================================${NC}"
say "${BLUE}Oh My Zsh Configuration Remover${NC}"
say "${BLUE}==================================${NC}\n"

if ! ask_yes_no "Are you sure you want to remove the Oh My Zsh setup? (y/N)" n; then
    say "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Restore .zshrc from backup if it exists
say "${YELLOW}[1/7] Checking for .zshrc backup...${NC}"
LATEST_BACKUP=""
for candidate in "$HOME"/.zshrc.backup.*; do
    [ -e "$candidate" ] || continue
    if [ -z "$LATEST_BACKUP" ] || [ "$candidate" -nt "$LATEST_BACKUP" ]; then
        LATEST_BACKUP="$candidate"
    fi
done
if [ -n "$LATEST_BACKUP" ]; then
    if ask_yes_no "Restore .zshrc from backup? (Y/n)" y; then
        cp "$LATEST_BACKUP" "$HOME/.zshrc"
        say "${GREEN}✓ .zshrc restored from $LATEST_BACKUP${NC}"
    else
        say "${YELLOW}Keeping current .zshrc${NC}"
    fi
else
    say "${YELLOW}No .zshrc backup found${NC}"
fi

# Handle .zshrc.local
say "${YELLOW}[2/7] Handling .zshrc.local...${NC}"
if [ -f "$HOME/.zshrc.local" ]; then
    if ask_yes_no "Backup and remove .zshrc.local (personal customizations)? (Y/n)" y; then
        BACKUP_FILE="$HOME/.zshrc.local.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME/.zshrc.local" "$BACKUP_FILE"
        rm -f "$HOME/.zshrc.local"
        say "${GREEN}✓ .zshrc.local backed up to $BACKUP_FILE and removed${NC}"
    else
        say "${YELLOW}Keeping .zshrc.local${NC}"
    fi
fi

# Remove plugins
say "${YELLOW}[3/7] Removing plugins...${NC}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    rm -rf "$ZSH_CUSTOM/plugins/$plugin"
    if [ -d "$ZSH_DIR/plugins/$plugin" ] && ! is_tracked "plugins/$plugin"; then
        rm -rf "$ZSH_DIR/plugins/$plugin"
    fi
    say "${GREEN}✓ $plugin removed${NC}"
done

# Remove spaceship theme
say "${YELLOW}[4/7] Removing spaceship theme...${NC}"
rm -rf "$ZSH_CUSTOM/themes/spaceship-prompt"
rm -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
if [ -d "$ZSH_DIR/themes/spaceship-prompt" ] && ! is_tracked "themes/spaceship-prompt"; then
    rm -rf "$ZSH_DIR/themes/spaceship-prompt"
fi
if ! is_tracked "themes/spaceship.zsh-theme"; then
    rm -f "$ZSH_DIR/themes/spaceship.zsh-theme"
fi
say "${GREEN}✓ spaceship theme removed${NC}"

# Remove fzf (only if this repo installed it, i.e. it is a git clone)
say "${YELLOW}[5/7] Handling fzf...${NC}"
if [ -d "$HOME/.fzf/.git" ]; then
    if ask_yes_no "Remove ~/.fzf? (y/N)" n; then
        rm -rf "$HOME/.fzf"
        say "${GREEN}✓ fzf removed${NC}"
    else
        say "${YELLOW}Keeping fzf${NC}"
    fi
else
    say "${YELLOW}No repo-installed fzf found${NC}"
fi

# Restore the default login shell if it currently points at zsh
say "${YELLOW}[6/7] Checking default shell...${NC}"
CURRENT_USER="$(id -un)"
CURRENT_SHELL="$(getent passwd "$CURRENT_USER" 2>/dev/null | cut -d: -f7 || true)"
if [ -n "$CURRENT_SHELL" ] && [ "$(basename "$CURRENT_SHELL")" = "zsh" ] && command -v bash >/dev/null 2>&1; then
    if ask_yes_no "Restore default shell to bash? (y/N)" n; then
        if run_root chsh -s "$(command -v bash)" "$CURRENT_USER"; then
            say "${GREEN}✓ Default shell restored to bash${NC}"
        else
            say "${YELLOW}Could not change the default shell${NC}"
        fi
    else
        say "${YELLOW}Keeping zsh as the default shell${NC}"
    fi
else
    say "${YELLOW}Default shell is not zsh; nothing to restore${NC}"
fi

# Remove Oh My Zsh (optional)
say "${YELLOW}[7/7] Oh My Zsh directory cleanup...${NC}"
if ask_yes_no "Remove entire Oh My Zsh directory ($ZSH_DIR)? (y/N)" n; then
    rm -rf "$ZSH_DIR"
    say "${GREEN}✓ Oh My Zsh directory removed${NC}"
else
    say "${YELLOW}Keeping Oh My Zsh directory${NC}"
fi

say "\n${GREEN}==================================${NC}"
say "${GREEN}Removal Complete!${NC}"
say "${GREEN}==================================${NC}\n"
