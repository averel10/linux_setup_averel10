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

# Third-party plugins/themes go in $ZSH_CUSTOM, never in the Oh My Zsh git
# checkout. Cloning into $ZSH/plugins or $ZSH/themes creates untracked files
# that make `omz update` abort with "untracked working tree files would be
# overwritten by merge" once Oh My Zsh tracks those same paths.
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"

is_tracked() { git -C "$ZSH_DIR" ls-files --error-unmatch "$1" >/dev/null 2>&1; }

install_plugin() {
    local name="$1" url="$2"
    # Migrate a legacy untracked clone out of the Oh My Zsh checkout.
    if [ -d "$ZSH_DIR/plugins/$name" ] && ! is_tracked "plugins/$name"; then
        if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
            mv "$ZSH_DIR/plugins/$name" "$ZSH_CUSTOM/plugins/$name"
            echo -e "${GREEN}  ✓ $name moved out of the Oh My Zsh repo${NC}"
        else
            rm -rf "$ZSH_DIR/plugins/$name"
            echo -e "${GREEN}  ✓ removed legacy $name from the Oh My Zsh repo${NC}"
        fi
    fi
    if [ -d "$ZSH_DIR/plugins/$name" ]; then
        echo -e "${GREEN}  ✓ $name bundled with Oh My Zsh${NC}"
    elif [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
        echo "  Installing $name..."
        git clone "$url" "$ZSH_CUSTOM/plugins/$name"
        echo -e "${GREEN}  ✓ $name installed${NC}"
    else
        echo -e "${GREEN}  ✓ $name already installed${NC}"
    fi
}

# Install plugins
echo -e "${YELLOW}[4/7] Installing required plugins...${NC}"
install_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
install_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# Install spaceship theme
echo -e "${YELLOW}[5/7] Installing spaceship theme...${NC}"
if [ -d "$ZSH_DIR/themes/spaceship-prompt" ] && ! is_tracked "themes/spaceship-prompt"; then
    if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
        mv "$ZSH_DIR/themes/spaceship-prompt" "$ZSH_CUSTOM/themes/spaceship-prompt"
    else
        rm -rf "$ZSH_DIR/themes/spaceship-prompt"
    fi
    rm -f "$ZSH_DIR/themes/spaceship.zsh-theme"
    echo -e "${GREEN}  ✓ spaceship moved out of the Oh My Zsh repo${NC}"
fi
if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
    echo "  Installing spaceship theme..."
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
    echo -e "${GREEN}  ✓ spaceship theme installed${NC}"
else
    echo -e "${GREEN}  ✓ spaceship theme already installed${NC}"
fi
ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

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
    sudo chsh -s "$ZSH_PATH" "$USER"
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
