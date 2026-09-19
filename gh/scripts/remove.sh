#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

GH_CONFIG_DIR="${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
GH_COMPLETION="$ZSH_CUSTOM_DIR/gh.zsh"
GH_LOCAL_DIR="$HOME/.local/opt/gh"

say "${BLUE}==================================${NC}"
say "${BLUE}GitHub CLI Remover${NC}"
say "${BLUE}==================================${NC}\n"

if [ "$SETUP_DRY_RUN" = "1" ]; then
    say "[dry-run] Would offer to remove $GH_COMPLETION, $GH_CONFIG_DIR,"
    say "[dry-run] and a locally installed gh at $GH_LOCAL_DIR."
    say "[dry-run] The gh binary is left installed."
    exit 0
fi

if ! ask_yes_no "Are you sure you want to remove the GitHub CLI setup? (y/N)" n; then
    say "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Remove the completion file we own
say "${YELLOW}[1/3] Handling zsh completion...${NC}"
if [ -f "$GH_COMPLETION" ]; then
    if ask_yes_no "Remove zsh completion ($GH_COMPLETION)? (Y/n)" y; then
        rm -f "$GH_COMPLETION"
        say "${GREEN}✓ completion removed${NC}"
    else
        say "${YELLOW}Keeping completion${NC}"
    fi
else
    say "${YELLOW}No completion file found${NC}"
fi

# Config holds auth tokens, so never remove it without an explicit yes
say "${YELLOW}[2/3] Handling gh config and auth...${NC}"
if [ -d "$GH_CONFIG_DIR" ]; then
    if ask_yes_no "Remove gh config and auth tokens ($GH_CONFIG_DIR)? (y/N)" n; then
        BACKUP_FILE="$(backup_path "$GH_CONFIG_DIR")"
        rm -rf "$GH_CONFIG_DIR"
        say "${GREEN}✓ gh config backed up to $BACKUP_FILE and removed${NC}"
    else
        say "${YELLOW}Keeping gh config${NC}"
    fi
else
    say "${YELLOW}No gh config found${NC}"
fi

# Remove a locally installed gh (official release fallback), if present
say "${YELLOW}[3/3] Handling locally installed gh...${NC}"
if [ -d "$GH_LOCAL_DIR" ]; then
    if ask_yes_no "Remove locally installed gh at $GH_LOCAL_DIR? (y/N)" n; then
        rm -rf "$GH_LOCAL_DIR"
        rm -f "$HOME/.local/bin/gh"
        say "${GREEN}✓ local gh removed${NC}"
    else
        say "${YELLOW}Keeping local gh${NC}"
    fi
else
    say "${YELLOW}No locally installed gh found${NC}"
fi

say "\n${GREEN}==================================${NC}"
say "${GREEN}Removal Complete!${NC}"
say "${GREEN}==================================${NC}\n"
