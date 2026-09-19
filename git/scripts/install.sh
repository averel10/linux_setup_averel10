#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

DOTFILES="$SCRIPT_DIR/../dotfiles"
GITCONFIG="$HOME/.gitconfig"
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
GITIGNORE_GLOBAL="$HOME/.gitignore_global"

say "${BLUE}==================================${NC}"
say "${BLUE}Git Configuration Installer${NC}"
say "${BLUE}==================================${NC}\n"

if [ "$SETUP_DRY_RUN" = "1" ]; then
    say "[dry-run] Would ensure git is installed and deploy ~/.gitconfig,"
    say "[dry-run] ~/.gitconfig.local, and ~/.gitignore_global (backing up existing files)."
    exit 0
fi

# Ensure git itself is present
say "${YELLOW}[1/4] Checking for git installation...${NC}"
if ! have_cmd git; then
    say "${YELLOW}git is not installed; installing it...${NC}"
    pkg_update
    pkg_install git
fi
say "${GREEN}✓ git found at $(command -v git)${NC}"

# Install ~/.gitconfig
say "${YELLOW}[2/4] Installing .gitconfig...${NC}"
BACKUP_FILE="$(backup_path "$GITCONFIG")"
if [ -n "$BACKUP_FILE" ]; then
    say "${YELLOW}  ⚠ Existing .gitconfig backed up to: $BACKUP_FILE${NC}"
fi
cp "$DOTFILES/.gitconfig" "$GITCONFIG"
say "${GREEN}✓ .gitconfig installed to $GITCONFIG${NC}"

# Install ~/.gitignore_global
say "${YELLOW}[3/4] Installing .gitignore_global...${NC}"
BACKUP_FILE="$(backup_path "$GITIGNORE_GLOBAL")"
if [ -n "$BACKUP_FILE" ]; then
    say "${YELLOW}  ⚠ Existing .gitignore_global backed up to: $BACKUP_FILE${NC}"
fi
cp "$DOTFILES/.gitignore_global" "$GITIGNORE_GLOBAL"
say "${GREEN}✓ .gitignore_global installed to $GITIGNORE_GLOBAL${NC}"

# Create ~/.gitconfig.local and optionally capture identity
say "${YELLOW}[4/4] Setting up .gitconfig.local...${NC}"
if [ ! -f "$GITCONFIG_LOCAL" ]; then
    cp "$DOTFILES/.gitconfig.local" "$GITCONFIG_LOCAL"
    say "${GREEN}✓ .gitconfig.local created at $GITCONFIG_LOCAL${NC}"
    if [ -t 0 ]; then
        GIT_NAME=""
        GIT_EMAIL=""
        read -r -p "Git user.name (leave blank to skip): " GIT_NAME || true
        if [ -n "$GIT_NAME" ]; then
            git config --file "$GITCONFIG_LOCAL" user.name "$GIT_NAME"
        fi
        read -r -p "Git user.email (leave blank to skip): " GIT_EMAIL || true
        if [ -n "$GIT_EMAIL" ]; then
            git config --file "$GITCONFIG_LOCAL" user.email "$GIT_EMAIL"
        fi
    else
        say "${YELLOW}  ℹ Set your identity in ~/.gitconfig.local${NC}"
    fi
else
    say "${GREEN}✓ .gitconfig.local already exists (not overwritten)${NC}"
fi

say "\n${GREEN}==================================${NC}"
say "${GREEN}Installation Complete!${NC}"
say "${GREEN}==================================${NC}"
say "\n${YELLOW}Configuration Files:${NC}"
say "  • ${BLUE}~/.gitconfig${NC} - Main config (managed by this repo)"
say "  • ${BLUE}~/.gitconfig.local${NC} - Your identity/overrides (safe to edit)"
say "  • ${BLUE}~/.gitignore_global${NC} - Global ignore patterns"
say "\nTo remove this setup later, run:"
say "  ${BLUE}$SCRIPT_DIR/remove.sh${NC}\n"
