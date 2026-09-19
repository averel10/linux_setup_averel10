#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../lib/common.sh
. "$SCRIPT_DIR/../../lib/common.sh"

# gh keeps its config (including auth tokens) here; we never overwrite it,
# we only run `gh config set` for missing defaults.
GH_CONFIG_DIR="${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}"
# If Oh My Zsh is present, drop a completion file into its custom dir.
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
GH_COMPLETION="$ZSH_CUSTOM_DIR/gh.zsh"

# Download the official static release (used only when the package manager
# has no gh package, e.g. older Ubuntu/Debian). Linux only; macOS uses brew.
install_gh_release() {
    local os arch tag version url tmp
    os="$(uname -s)"
    if [ "$os" != "Linux" ]; then
        warn "No gh package found and automatic install is only supported on Linux"
        warn "On macOS install with: brew install gh"
        return 1
    fi

    case "$(uname -m)" in
        x86_64|amd64) arch=amd64 ;;
        aarch64|arm64) arch=arm64 ;;
        armv7l|armv6l) arch=armv6 ;;
        i386|i686) arch=386 ;;
        *) warn "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac

    tag="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null \
        | grep -m1 '"tag_name"' | cut -d'"' -f4 || true)"
    if [ -z "$tag" ]; then
        warn "Could not determine the latest gh release"
        return 1
    fi
    version="${tag#v}"
    url="https://github.com/cli/cli/releases/download/${tag}/gh_${version}_linux_${arch}.tar.gz"

    tmp="$(mktemp -d)"
    if ! curl -fsSL "$url" -o "$tmp/gh.tar.gz"; then
        rm -rf "$tmp"
        warn "Could not download $url"
        return 1
    fi
    tar -xzf "$tmp/gh.tar.gz" -C "$tmp"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    rm -rf "$HOME/.local/opt/gh"
    mv "$tmp"/gh_* "$HOME/.local/opt/gh"
    ln -sf "$HOME/.local/opt/gh/bin/gh" "$HOME/.local/bin/gh"
    rm -rf "$tmp"
}

say "${BLUE}==================================${NC}"
say "${BLUE}GitHub CLI Installer${NC}"
say "${BLUE}==================================${NC}\n"

if [ "$SETUP_DRY_RUN" = "1" ]; then
    say "[dry-run] GH_CONFIG_DIR=$GH_CONFIG_DIR"
    say "[dry-run] Would ensure gh is installed, set default config values,"
    say "[dry-run] install a zsh completion file, and optionally run 'gh auth login'."
    exit 0
fi

# Ensure gh is installed
say "${YELLOW}[1/4] Checking for GitHub CLI installation...${NC}"
if ! have_cmd gh; then
    say "${YELLOW}gh is not installed; installing it...${NC}"
    pkg_update || true
    if ! pkg_install gh; then
        warn "Package manager could not install gh; trying the official release"
        install_gh_release || die "Could not install gh"
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi
have_cmd gh || die "gh installation failed"
say "${GREEN}✓ gh found at $(command -v gh)${NC}"

# Set defaults without clobbering existing user config
say "${YELLOW}[2/4] Configuring gh defaults...${NC}"
if [ -z "$(gh config get git_protocol 2>/dev/null || true)" ]; then
    gh config set git_protocol https
    say "${GREEN}✓ git_protocol set to https${NC}"
else
    say "${GREEN}✓ git_protocol already configured${NC}"
fi

# Install zsh completion if Oh My Zsh's custom dir is present
say "${YELLOW}[3/4] Installing zsh completion...${NC}"
if [ -d "$ZSH_CUSTOM_DIR" ]; then
    gh completion -s zsh > "$GH_COMPLETION"
    say "${GREEN}✓ completion written to $GH_COMPLETION${NC}"
else
    say "${YELLOW}No Oh My Zsh custom dir found; skipping completion${NC}"
fi

# Offer interactive authentication
say "${YELLOW}[4/4] Checking authentication...${NC}"
if gh auth status >/dev/null 2>&1; then
    say "${GREEN}✓ already authenticated with GitHub${NC}"
elif [ -t 0 ]; then
    if ask_yes_no "Authenticate with GitHub now (gh auth login)? (Y/n)" y; then
        gh auth login
    else
        say "${YELLOW}Skipping authentication; run 'gh auth login' later${NC}"
    fi
else
    say "${YELLOW}Not authenticated; run 'gh auth login' in a terminal${NC}"
fi

say "\n${GREEN}==================================${NC}"
say "${GREEN}Installation Complete!${NC}"
say "${GREEN}==================================${NC}"
say "\n${YELLOW}Config:${NC}"
say "  • ${BLUE}$GH_CONFIG_DIR${NC} - gh config and auth (managed by gh)"
if [ -f "$GH_COMPLETION" ]; then
    say "  • ${BLUE}$GH_COMPLETION${NC} - zsh completion"
fi
say "\nTo remove this setup later, run:"
say "  ${BLUE}$SCRIPT_DIR/remove.sh${NC}\n"
