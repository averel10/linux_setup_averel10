#!/bin/bash

set -euo pipefail

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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Location of the Oh My Zsh checkout. Third-party plugins/themes go in
# $ZSH_CUSTOM (gitignored), never directly in the checkout.
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# Run a command as root, using sudo only when not already root.
run_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        if ! command -v sudo >/dev/null 2>&1; then
            say "${RED}✗ This step requires root or sudo, which was not found${NC}"
            exit 1
        fi
        sudo "$@"
    fi
}

say "${BLUE}==================================${NC}"
say "${BLUE}Oh My Zsh Configuration Installer${NC}"
say "${BLUE}==================================${NC}\n"

# Install zsh via the available package manager.
install_zsh() {
    say "${YELLOW}Attempting to install zsh...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        run_root apt-get update
        run_root apt-get install -y zsh
    elif command -v dnf >/dev/null 2>&1; then
        run_root dnf install -y zsh
    elif command -v yum >/dev/null 2>&1; then
        run_root yum install -y zsh
    elif command -v pacman >/dev/null 2>&1; then
        run_root pacman -Sy --noconfirm zsh
    elif command -v brew >/dev/null 2>&1; then
        brew install zsh
    else
        say "${RED}✗ Could not detect a package manager to install zsh${NC}"
        say "Please install zsh manually, then re-run this script."
        exit 1
    fi
}

# Check if zsh is installed
say "${YELLOW}[1/7] Checking for zsh installation...${NC}"
if ! command -v zsh >/dev/null 2>&1; then
    say "${RED}✗ zsh is not installed${NC}"
    install_zsh
fi
ZSH_PATH="$(command -v zsh)"
say "${GREEN}✓ zsh found at $ZSH_PATH${NC}"

# Check if Oh My Zsh is installed
say "${YELLOW}[2/7] Checking for Oh My Zsh installation...${NC}"
if [ ! -d "$ZSH_DIR" ]; then
    say "${YELLOW}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    say "${GREEN}✓ Oh My Zsh installed successfully${NC}"
else
    say "${GREEN}✓ Oh My Zsh already installed${NC}"
fi

# Install fzf
say "${YELLOW}[3/7] Checking for fzf installation...${NC}"
if [ ! -d "$HOME/.fzf" ]; then
    say "${YELLOW}Installing fzf...${NC}"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
    say "${GREEN}✓ fzf installed${NC}"
else
    say "${GREEN}✓ fzf already installed${NC}"
fi

# Install plugins into $ZSH_CUSTOM (NOT the Oh My Zsh git checkout).
# Cloning into $ZSH/plugins creates untracked files that make `omz update`
# abort with "untracked working tree files would be overwritten by merge".
is_tracked() { git -C "$ZSH_DIR" ls-files --error-unmatch "$1" >/dev/null 2>&1; }

install_plugin() {
    local name="$1" url="$2"
    # Migrate a legacy untracked clone out of the Oh My Zsh checkout.
    if [ -d "$ZSH_DIR/plugins/$name" ] && ! is_tracked "plugins/$name"; then
        if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
            mv "$ZSH_DIR/plugins/$name" "$ZSH_CUSTOM/plugins/$name"
            say "${GREEN}  ✓ $name moved out of the Oh My Zsh repo${NC}"
        else
            rm -rf "$ZSH_DIR/plugins/$name"
            say "${GREEN}  ✓ removed legacy $name from the Oh My Zsh repo${NC}"
        fi
    fi
    if [ -d "$ZSH_DIR/plugins/$name" ]; then
        say "${GREEN}  ✓ $name bundled with Oh My Zsh${NC}"
    elif [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
        say "  Installing $name..."
        git clone "$url" "$ZSH_CUSTOM/plugins/$name"
        say "${GREEN}  ✓ $name installed${NC}"
    else
        say "${GREEN}  ✓ $name already installed${NC}"
    fi
}

say "${YELLOW}[4/7] Installing required plugins...${NC}"
mkdir -p "$ZSH_CUSTOM/plugins"
install_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
install_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# Install spaceship theme
say "${YELLOW}[5/7] Installing spaceship theme...${NC}"
mkdir -p "$ZSH_CUSTOM/themes"
if [ -d "$ZSH_DIR/themes/spaceship-prompt" ] && ! is_tracked "themes/spaceship-prompt"; then
    if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
        mv "$ZSH_DIR/themes/spaceship-prompt" "$ZSH_CUSTOM/themes/spaceship-prompt"
    else
        rm -rf "$ZSH_DIR/themes/spaceship-prompt"
    fi
    rm -f "$ZSH_DIR/themes/spaceship.zsh-theme"
    say "${GREEN}  ✓ spaceship moved out of the Oh My Zsh repo${NC}"
fi
if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
    say "  Installing spaceship theme..."
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
    say "${GREEN}  ✓ spaceship theme installed${NC}"
else
    say "${GREEN}  ✓ spaceship theme already installed${NC}"
fi
ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

# Backup existing .zshrc and install new one
say "${YELLOW}[6/7] Installing .zshrc configuration...${NC}"
if [ -f "$HOME/.zshrc" ]; then
    BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.zshrc" "$BACKUP_FILE"
    say "${YELLOW}  ⚠ Existing .zshrc backed up to: $BACKUP_FILE${NC}"
fi

cp "$SCRIPT_DIR/../dotfiles/.zshrc" "$HOME/.zshrc"
say "${GREEN}✓ .zshrc installed to $HOME/.zshrc${NC}"

# Create or update .zshrc.local for local overrides
if [ ! -f "$HOME/.zshrc.local" ]; then
    cp "$SCRIPT_DIR/../dotfiles/.zshrc.local" "$HOME/.zshrc.local"
    say "${GREEN}✓ .zshrc.local created at $HOME/.zshrc.local${NC}"
    say "${YELLOW}  ℹ Add personal customizations to ~/.zshrc.local${NC}"
else
    say "${GREEN}✓ .zshrc.local already exists (not overwritten)${NC}"
fi

# Set zsh as the default shell
say "${YELLOW}[7/7] Setting zsh as default shell...${NC}"
CURRENT_USER="$(id -un)"
if [ "$(getent passwd "$CURRENT_USER" 2>/dev/null | cut -d: -f7 || true)" != "$ZSH_PATH" ] \
    && [ "$SHELL" != "$ZSH_PATH" ]; then
    run_root chsh -s "$ZSH_PATH" "$CURRENT_USER"
    say "${GREEN}✓ Default shell changed to $ZSH_PATH${NC}"
else
    say "${GREEN}✓ zsh is already the default shell${NC}"
fi

say "\n${GREEN}==================================${NC}"
say "${GREEN}Installation Complete!${NC}"
say "${GREEN}==================================${NC}"
say "\nTo start using zsh, either:"
say "  1. ${BLUE}Restart your terminal${NC} (if you changed the default shell)"
say "  2. Run: ${BLUE}exec zsh${NC}"
say "  3. Run: ${BLUE}source ~/.zshrc${NC}"
say "\n${YELLOW}Configuration Files:${NC}"
say "  • ${BLUE}~/.zshrc${NC} - Main config (managed by this repo)"
say "  • ${BLUE}~/.zshrc.local${NC} - Your personal customizations (safe to edit)"
say "\n${YELLOW}For updates:${NC}"
say "  Just run this script again - it won't overwrite ~/.zshrc.local!"
say "\nTo remove this setup later, run:"
say "  ${BLUE}$SCRIPT_DIR/remove.sh${NC}\n"
