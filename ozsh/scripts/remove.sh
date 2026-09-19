#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Oh My Zsh Configuration Remover${NC}"
echo -e "${BLUE}==================================${NC}\n"

read -p "Are you sure you want to remove the Oh My Zsh setup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Restore .zshrc from backup if it exists
echo -e "${YELLOW}[1/5] Checking for .zshrc backup...${NC}"
LATEST_BACKUP=$(ls -t "$HOME"/.zshrc.backup.* 2>/dev/null | head -n 1)
if [ -n "$LATEST_BACKUP" ]; then
    read -p "Restore .zshrc from backup? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cp "$LATEST_BACKUP" "$HOME/.zshrc"
        echo -e "${GREEN}✓ .zshrc restored from $LATEST_BACKUP${NC}"
    else
        echo -e "${YELLOW}Keeping current .zshrc${NC}"
    fi
else
    echo -e "${YELLOW}No .zshrc backup found${NC}"
fi

# Handle .zshrc.local
echo -e "${YELLOW}[2/5] Handling .zshrc.local...${NC}"
if [ -f "$HOME/.zshrc.local" ]; then
    read -p "Backup .zshrc.local (your personal customizations)? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        BACKUP_FILE="$HOME/.zshrc.local.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME/.zshrc.local" "$BACKUP_FILE"
        echo -e "${GREEN}✓ .zshrc.local backed up to $BACKUP_FILE${NC}"
        rm -f "$HOME/.zshrc.local"
    else
        rm -f "$HOME/.zshrc.local"
    fi
fi

# Third-party plugins/themes live in $ZSH_CUSTOM. Never delete paths tracked
# by the Oh My Zsh repo itself.
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
is_tracked() { git -C "$ZSH_DIR" ls-files --error-unmatch "$1" >/dev/null 2>&1; }

# Remove plugins
echo -e "${YELLOW}[3/5] Removing plugins...${NC}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    rm -rf "$ZSH_CUSTOM/plugins/$plugin"
    if [ -d "$ZSH_DIR/plugins/$plugin" ] && ! is_tracked "plugins/$plugin"; then
        rm -rf "$ZSH_DIR/plugins/$plugin"
    fi
    echo -e "${GREEN}✓ $plugin removed${NC}"
done

# Remove spaceship theme
echo -e "${YELLOW}[4/5] Removing spaceship theme...${NC}"
rm -rf "$ZSH_CUSTOM/themes/spaceship-prompt"
rm -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
if [ -d "$ZSH_DIR/themes/spaceship-prompt" ] && ! is_tracked "themes/spaceship-prompt"; then
    rm -rf "$ZSH_DIR/themes/spaceship-prompt"
fi
rm -f "$ZSH_DIR/themes/spaceship.zsh-theme"
echo -e "${GREEN}✓ spaceship theme removed${NC}"

# Remove Oh My Zsh (optional)
echo -e "${YELLOW}[5/5] Oh My Zsh directory cleanup...${NC}"
read -p "Remove entire Oh My Zsh directory? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.oh-my-zsh"
    echo -e "${GREEN}✓ Oh My Zsh directory removed${NC}"
else
    echo -e "${YELLOW}Keeping Oh My Zsh directory${NC}"
fi

echo -e "\n${GREEN}==================================${NC}"
echo -e "${GREEN}Removal Complete!${NC}"
echo -e "${GREEN}==================================${NC}\n"
