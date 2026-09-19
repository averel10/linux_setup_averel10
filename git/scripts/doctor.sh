#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

GITCONFIG="$HOME/.gitconfig"

issues=0
check_ok() { say "  ${GREEN}✓${NC} $1"; }
check_bad() { say "  ${RED}✗${NC} $1"; issues=$((issues+1)); }
check_warn() { say "  ${YELLOW}⚠${NC} $1"; }

if have_cmd git; then
    check_ok "git installed ($(command -v git))"
else
    check_bad "git is not installed"
fi

if [ -f "$GITCONFIG" ]; then
    check_ok "$HOME/.gitconfig present"
else
    check_bad "$HOME/.gitconfig missing"
fi

if [ -f "$HOME/.gitconfig.local" ]; then
    check_ok "$HOME/.gitconfig.local present"
else
    check_bad "$HOME/.gitconfig.local missing"
fi

if [ -f "$HOME/.gitignore_global" ]; then
    check_ok "$HOME/.gitignore_global present"
else
    check_bad "$HOME/.gitignore_global missing"
fi

if [ -f "$GITCONFIG" ] && [ -n "$(git config --file "$GITCONFIG" --get include.path 2>/dev/null || true)" ]; then
    check_ok "$HOME/.gitconfig includes $HOME/.gitconfig.local"
else
    check_bad "$HOME/.gitconfig does not include $HOME/.gitconfig.local"
fi

if have_cmd git && [ -n "$(git config --global user.email 2>/dev/null || true)" ]; then
    check_ok "git identity configured ($(git config --global user.email))"
else
    check_warn "git user.email is not configured (set it in ~/.gitconfig.local)"
fi

if [ "$issues" -eq 0 ]; then
    exit 0
fi
exit 1
