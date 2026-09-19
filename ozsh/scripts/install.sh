#!/bin/bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

# Location of the Oh My Zsh checkout. Third-party plugins/themes go in
# $ZSH_CUSTOM (gitignored), never directly in the checkout.
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# Paths tracked by the Oh My Zsh repo itself must never be moved or deleted.
is_tracked() { git -C "$ZSH_DIR" ls-files --error-unmatch "$1" >/dev/null 2>&1; }

say "${BLUE}==================================${NC}"
say "${BLUE}Oh My Zsh Configuration Installer${NC}"
say "${BLUE}==================================${NC}\n"

if [ "$SETUP_DRY_RUN" = "1" ]; then
    say "[dry-run] ZSH_DIR=$ZSH_DIR ZSH_CUSTOM=$ZSH_CUSTOM"
    say "[dry-run] Would ensure: zsh, Oh My Zsh, fzf, zsh-autosuggestions,"
    say "[dry-run] zsh-syntax-highlighting, spaceship theme, ~/.zshrc, zsh login shell."
    exit 0
fi

# Check if zsh is installed
say "${YELLOW}[1/7] Checking for zsh installation...${NC}"
if ! have_cmd zsh; then
    say "${YELLOW}zsh is not installed; installing it...${NC}"
    pkg_update
    pkg_install zsh
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
BACKUP_FILE="$(backup_path "$HOME/.zshrc")"
if [ -n "$BACKUP_FILE" ]; then
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
