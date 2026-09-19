#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

GITCONFIG="$HOME/.gitconfig"
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
GITIGNORE_GLOBAL="$HOME/.gitignore_global"

say "${BLUE}==================================${NC}"
say "${BLUE}Git Configuration Remover${NC}"
say "${BLUE}==================================${NC}\n"

if [ "$SETUP_DRY_RUN" = "1" ]; then
    say "[dry-run] Would offer to restore/remove ~/.gitconfig, ~/.gitconfig.local,"
    say "[dry-run] and ~/.gitignore_global. Git itself is left installed."
    exit 0
fi

if ! ask_yes_no "Are you sure you want to remove the Git setup? (y/N)" n; then
    say "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Restore or remove ~/.gitconfig
say "${YELLOW}[1/3] Handling .gitconfig...${NC}"
LATEST_BACKUP=""
for candidate in "$HOME"/.gitconfig.backup.*; do
    [ -e "$candidate" ] || continue
    if [ -z "$LATEST_BACKUP" ] || [ "$candidate" -nt "$LATEST_BACKUP" ]; then
        LATEST_BACKUP="$candidate"
    fi
done
if [ -n "$LATEST_BACKUP" ]; then
    if ask_yes_no "Restore .gitconfig from backup? (Y/n)" y; then
        cp "$LATEST_BACKUP" "$GITCONFIG"
        say "${GREEN}✓ .gitconfig restored from $LATEST_BACKUP${NC}"
    else
        say "${YELLOW}Keeping current .gitconfig${NC}"
    fi
elif [ -f "$GITCONFIG" ] && ask_yes_no "Remove managed .gitconfig? (y/N)" n; then
    rm -f "$GITCONFIG"
    say "${GREEN}✓ .gitconfig removed${NC}"
else
    say "${YELLOW}Keeping .gitconfig${NC}"
fi

# Handle ~/.gitconfig.local
say "${YELLOW}[2/3] Handling .gitconfig.local...${NC}"
if [ -f "$GITCONFIG_LOCAL" ]; then
    if ask_yes_no "Backup and remove .gitconfig.local? (Y/n)" y; then
        BACKUP_FILE="$(backup_path "$GITCONFIG_LOCAL")"
        rm -f "$GITCONFIG_LOCAL"
        say "${GREEN}✓ .gitconfig.local backed up to $BACKUP_FILE and removed${NC}"
    else
        say "${YELLOW}Keeping .gitconfig.local${NC}"
    fi
fi

# Handle ~/.gitignore_global
say "${YELLOW}[3/3] Handling .gitignore_global...${NC}"
if [ -f "$GITIGNORE_GLOBAL" ]; then
    if ask_yes_no "Backup and remove .gitignore_global? (Y/n)" y; then
        BACKUP_FILE="$(backup_path "$GITIGNORE_GLOBAL")"
        rm -f "$GITIGNORE_GLOBAL"
        say "${GREEN}✓ .gitignore_global backed up to $BACKUP_FILE and removed${NC}"
    else
        say "${YELLOW}Keeping .gitignore_global${NC}"
    fi
fi

say "\n${GREEN}==================================${NC}"
say "${GREEN}Removal Complete!${NC}"
say "${GREEN}==================================${NC}\n"
