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

# Remove plugins
echo -e "${YELLOW}[3/5] Removing plugins...${NC}"
rm -rf "$HOME/.oh-my-zsh/plugins/zsh-autosuggestions"
echo -e "${GREEN}✓ zsh-autosuggestions removed${NC}"

rm -rf "$HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting"
echo -e "${GREEN}✓ zsh-syntax-highlighting removed${NC}"

# Remove spaceship theme
echo -e "${YELLOW}[4/5] Removing spaceship theme...${NC}"
rm -rf "$HOME/.oh-my-zsh/themes/spaceship-prompt"
rm -f "$HOME/.oh-my-zsh/themes/spaceship.zsh-theme"
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
