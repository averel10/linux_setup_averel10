#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Oh My Zsh Configuration Installer${NC}"
echo -e "${BLUE}==================================${NC}\n"

# Check if zsh is installed
echo -e "${YELLOW}[1/7] Checking for zsh installation...${NC}"
if ! command -v zsh &> /dev/null; then
    echo -e "${RED}✗ zsh is not installed${NC}"
    echo "Please install zsh first:"
    echo "  Ubuntu/Debian: sudo apt-get install zsh"
    echo "  Fedora: sudo dnf install zsh"
    echo "  macOS: brew install zsh"
    exit 1
fi
echo -e "${GREEN}✓ zsh found at $(which zsh)${NC}"

# Check if Oh My Zsh is installed
echo -e "${YELLOW}[2/7] Checking for Oh My Zsh installation...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo -e "${GREEN}✓ Oh My Zsh installed successfully${NC}"
else
    echo -e "${GREEN}✓ Oh My Zsh already installed${NC}"
fi

# Install fzf
echo -e "${YELLOW}[3/7] Checking for fzf installation...${NC}"
if [ ! -d "$HOME/.fzf" ]; then
    echo -e "${YELLOW}Installing fzf...${NC}"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-fish
    echo -e "${GREEN}✓ fzf installed${NC}"
else
    echo -e "${GREEN}✓ fzf already installed${NC}"
fi

# Install plugins
echo -e "${YELLOW}[4/7] Installing required plugins...${NC}"

# zsh-autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/plugins/zsh-autosuggestions" ]; then
    echo "  Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/plugins/zsh-autosuggestions"
    echo -e "${GREEN}  ✓ zsh-autosuggestions installed${NC}"
else
    echo -e "${GREEN}  ✓ zsh-autosuggestions already installed${NC}"
fi

# zsh-syntax-highlighting
if [ ! -d "$HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting" ]; then
    echo "  Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting"
    echo -e "${GREEN}  ✓ zsh-syntax-highlighting installed${NC}"
else
    echo -e "${GREEN}  ✓ zsh-syntax-highlighting already installed${NC}"
fi

# Install spaceship theme
echo -e "${YELLOW}[5/7] Installing spaceship theme...${NC}"
if [ ! -d "$HOME/.oh-my-zsh/themes/spaceship-prompt" ]; then
    echo "  Installing spaceship theme..."
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/themes/spaceship-prompt" --depth=1
    ln -s "$HOME/.oh-my-zsh/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/themes/spaceship.zsh-theme"
    echo -e "${GREEN}  ✓ spaceship theme installed${NC}"
else
    echo -e "${GREEN}  ✓ spaceship theme already installed${NC}"
fi

# Backup existing .zshrc and install new one
echo -e "${YELLOW}[6/7] Installing .zshrc configuration...${NC}"
if [ -f "$HOME/.zshrc" ]; then
    BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$HOME/.zshrc" "$BACKUP_FILE"
    echo -e "${YELLOW}  ⚠ Existing .zshrc backed up to: $BACKUP_FILE${NC}"
fi

cp "$SCRIPT_DIR/../dotfiles/.zshrc" "$HOME/.zshrc"
echo -e "${GREEN}✓ .zshrc installed to $HOME/.zshrc${NC}"

# Create or update .zshrc.local for local overrides
if [ ! -f "$HOME/.zshrc.local" ]; then
    cp "$SCRIPT_DIR/../dotfiles/.zshrc.local" "$HOME/.zshrc.local"
    echo -e "${GREEN}✓ .zshrc.local created at $HOME/.zshrc.local${NC}"
    echo -e "${YELLOW}  ℹ Add personal customizations to ~/.zshrc.local${NC}"
else
    echo -e "${GREEN}✓ .zshrc.local already exists (not overwritten)${NC}"
fi

# Set zsh as the default shell
echo -e "${YELLOW}[7/7] Setting zsh as default shell...${NC}"
ZSH_PATH=$(which zsh)
if [ "$SHELL" != "$ZSH_PATH" ]; then
    read -p "Change default shell to zsh? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        chsh -s "$ZSH_PATH"
        echo -e "${GREEN}✓ Default shell changed to zsh${NC}"
        echo -e "${YELLOW}  ℹ You may need to restart your terminal for this to take effect${NC}"
    else
        echo -e "${YELLOW}⚠ Shell not changed (zsh will need to be set as default manually)${NC}"
    fi
else
    echo -e "${GREEN}✓ zsh is already the default shell${NC}"
fi

echo -e "\n${GREEN}==================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo -e "\nTo start using zsh, either:"
echo -e "  1. ${BLUE}Restart your terminal${NC} (if you changed the default shell)"
echo -e "  2. Run: ${BLUE}exec zsh${NC}"
echo -e "  3. Run: ${BLUE}source ~/.zshrc${NC}"
echo -e "\n${YELLOW}Configuration Files:${NC}"
echo -e "  • ${BLUE}~/.zshrc${NC} - Main config (managed by this repo)"
echo -e "  • ${BLUE}~/.zshrc.local${NC} - Your personal customizations (safe to edit)"
echo -e "\n${YELLOW}For updates:${NC}"
echo -e "  Just run this script again - it won't overwrite ~/.zshrc.local!"
echo -e "\nTo remove this setup later, run:"
echo -e "  ${BLUE}$(dirname "$0")/remove.sh${NC}\n"
