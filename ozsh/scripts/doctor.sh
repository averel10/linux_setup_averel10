#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

issues=0
check_ok() { say "  ${GREEN}✓${NC} $1"; }
check_bad() { say "  ${RED}✗${NC} $1"; issues=$((issues+1)); }
check_warn() { say "  ${YELLOW}⚠${NC} $1"; }

if have_cmd zsh; then
    check_ok "zsh installed ($(command -v zsh))"
else
    check_bad "zsh is not installed"
fi

if [ -d "$ZSH_DIR" ]; then
    check_ok "Oh My Zsh present at $ZSH_DIR"
else
    check_bad "Oh My Zsh missing at $ZSH_DIR"
fi

if [ -d "$HOME/.fzf" ]; then
    check_ok "fzf present at $HOME/.fzf"
else
    check_bad "fzf missing at $HOME/.fzf"
fi

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ -d "$ZSH_CUSTOM/plugins/$plugin" ] || [ -d "$ZSH_DIR/plugins/$plugin" ]; then
        check_ok "plugin $plugin installed"
    else
        check_bad "plugin $plugin missing"
    fi
done

if [ -e "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ] || [ -e "$ZSH_DIR/themes/spaceship.zsh-theme" ]; then
    check_ok "spaceship theme installed"
else
    check_bad "spaceship theme missing"
fi

if [ -f "$HOME/.zshrc" ] && grep -q 'oh-my-zsh.sh' "$HOME/.zshrc"; then
    check_ok "$HOME/.zshrc loads Oh My Zsh"
else
    check_bad "$HOME/.zshrc does not load Oh My Zsh"
fi

if [ -f "$HOME/.zshrc.local" ]; then
    check_ok "$HOME/.zshrc.local present"
else
    check_bad "$HOME/.zshrc.local missing (personal overrides)"
fi

CURRENT_SHELL="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || true)"
if [ -n "$CURRENT_SHELL" ] && [ "$(basename "$CURRENT_SHELL")" = "zsh" ]; then
    check_ok "login shell is zsh"
else
    check_warn "login shell is not zsh (currently: ${CURRENT_SHELL:-unknown})"
fi

if [ "$issues" -eq 0 ]; then
    exit 0
fi
exit 1
