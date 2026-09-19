#!/bin/bash
# Shared helpers for the component scripts in this repo.
#
# Source this file; do not execute it:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   . "$SCRIPT_DIR/../../lib/common.sh"

# Colors. `:=` so a caller that already defined them keeps its own values.
RED="${RED:-$'\033[0;31m'}"
GREEN="${GREEN:-$'\033[0;32m'}"
YELLOW="${YELLOW:-$'\033[1;33m'}"
BLUE="${BLUE:-$'\033[0;34m'}"
CYAN="${CYAN:-$'\033[0;36m'}"
NC="${NC:-$'\033[0m'}"

# Suppress status output with SETUP_QUIET=1 (set by `install.sh --quiet`).
# Errors are never suppressed.
SETUP_QUIET="${SETUP_QUIET:-0}"
# Preview actions without mutating anything with SETUP_DRY_RUN=1.
SETUP_DRY_RUN="${SETUP_DRY_RUN:-0}"

say() {
    [ "$SETUP_QUIET" = "1" ] || echo -e "$@"
}

warn() {
    say "${YELLOW}$*${NC}"
}

error() {
    echo -e "${RED}$*${NC}" >&2
}

die() {
    error "$*"
    exit 1
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Read a whole line so the trailing newline is not left for the next prompt.
# Usage: ask_yes_no "Question?" n   (defaults to no)
ask_yes_no() {
    local prompt=$1 default=${2:-n} reply
    read -r -p "$prompt " reply || true
    case $default in
        y|Y) [[ ! $reply =~ ^[Nn]$ ]] ;;
        *)   [[ $reply =~ ^[Yy]$ ]] ;;
    esac
}

# Run a command as root, using sudo only when not already root.
run_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        if ! have_cmd sudo; then
            error "This step requires root or sudo, which was not found"
            return 1
        fi
        if [ "$SETUP_DRY_RUN" = "1" ]; then
            say "[dry-run] sudo $*"
            return 0
        fi
        sudo "$@"
    fi
}

# Copy a file or directory to "<path>.backup.<timestamp>" and print the backup
# path. No-op (prints nothing) when the source does not exist.
backup_path() {
    local src=$1 stamp dest
    [ -e "$src" ] || return 0
    stamp="$(date +%Y%m%d_%H%M%S)"
    dest="${src}.backup.${stamp}"
    cp -a "$src" "$dest"
    printf '%s' "$dest"
}

# Print the detected package manager (apt, dnf, yum, pacman, brew) or nothing.
detect_pkg_manager() {
    if have_cmd apt-get; then
        printf 'apt'
    elif have_cmd dnf; then
        printf 'dnf'
    elif have_cmd yum; then
        printf 'yum'
    elif have_cmd pacman; then
        printf 'pacman'
    elif have_cmd brew; then
        printf 'brew'
    fi
}

# Refresh the package index for the detected package manager.
pkg_update() {
    case "$(detect_pkg_manager)" in
        apt)    run_root apt-get update ;;
        dnf)    run_root dnf check-update || true ;;
        yum)    run_root yum check-update || true ;;
        pacman) run_root pacman -Sy --noconfirm ;;
        brew)   run_root brew update ;;
        *)      die "No supported package manager found (apt/dnf/yum/pacman/brew)" ;;
    esac
}

# Install one or more packages using the detected package manager.
pkg_install() {
    [ $# -gt 0 ] || return 0
    case "$(detect_pkg_manager)" in
        apt)    run_root apt-get install -y "$@" ;;
        dnf)    run_root dnf install -y "$@" ;;
        yum)    run_root yum install -y "$@" ;;
        pacman) run_root pacman -S --noconfirm --needed "$@" ;;
        brew)   run_root brew install "$@" ;;
        *)      die "No supported package manager found (apt/dnf/yum/pacman/brew)" ;;
    esac
}
