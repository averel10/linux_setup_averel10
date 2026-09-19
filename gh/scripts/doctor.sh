#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

GH_CONFIG_DIR="${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
GH_COMPLETION="$ZSH_CUSTOM_DIR/gh.zsh"

issues=0
check_ok() { say "  ${GREEN}✓${NC} $1"; }
check_bad() { say "  ${RED}✗${NC} $1"; issues=$((issues+1)); }
check_warn() { say "  ${YELLOW}⚠${NC} $1"; }

if have_cmd gh; then
    check_ok "gh installed ($(gh --version 2>/dev/null | head -n 1 || true))"
else
    check_bad "gh is not installed"
fi

if have_cmd gh && gh auth status >/dev/null 2>&1; then
    check_ok "authenticated with GitHub"
else
    check_warn "not authenticated (run 'gh auth login')"
fi

if have_cmd gh && [ -n "$(gh config get git_protocol 2>/dev/null || true)" ]; then
    check_ok "git_protocol configured"
else
    check_warn "git_protocol not configured"
fi

if [ -f "$GH_COMPLETION" ]; then
    check_ok "zsh completion present"
else
    check_warn "zsh completion missing"
fi

if [ "$issues" -eq 0 ]; then
    exit 0
fi
exit 1
