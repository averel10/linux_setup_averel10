#!/bin/bash
# Hermetic test suite for the setup CLI. Runs entirely against a throwaway HOME
# with a stub `zsh`, so it never touches the real shell or downloads anything.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$REPO_DIR/install.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Stub zsh so the component installer never invokes a package manager.
mkdir -p "$WORK/bin"
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/zsh"
chmod +x "$WORK/bin/zsh"
export PATH="$WORK/bin:$PATH"
export SHELL="$WORK/bin/zsh"

PASS=0
FAIL=0
pass() { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL+1)); printf 'FAIL - %s\n' "$1"; }
assert_rc() { if [ "$1" -eq "$2" ]; then pass "$3"; else fail "$3 (expected rc=$1 got $2)"; fi; }
assert_contains() { case "$2" in *"$1"*) pass "$3" ;; *) fail "$3 (missing '$1')" ;; esac; }
assert_exists() { if [ -e "$1" ]; then pass "$2"; else fail "$2 (missing $1)"; fi; }
assert_absent() { if [ -e "$1" ]; then fail "$2 (still present: $1)"; else pass "$2"; fi; }
strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'; }

HOME_DIR=""
OUT=""
RC=0

# Run the CLI with the sandbox HOME and an optional stdin payload.
run() {
    local input=$1
    shift
    OUT="$(printf '%s' "$input" | env -u ZSH -u ZSH_CUSTOM HOME="$HOME_DIR" bash "$@" 2>&1)"
    RC=$?
}
run_noinput() {
    OUT="$(env -u ZSH -u ZSH_CUSTOM HOME="$HOME_DIR" bash "$@" 2>&1)"
    RC=$?
}

# Build a fake Oh My Zsh checkout with legacy untracked plugin/theme clones.
make_home() {
    HOME_DIR="$WORK/home"
    rm -rf "$HOME_DIR"
    mkdir -p "$HOME_DIR/.oh-my-zsh/plugins" "$HOME_DIR/.oh-my-zsh/themes" "$HOME_DIR/.fzf"
    git -C "$HOME_DIR/.oh-my-zsh" init -q
    printf 'custom/\n' > "$HOME_DIR/.oh-my-zsh/.gitignore"
    git -C "$HOME_DIR/.oh-my-zsh" add .gitignore
    git -C "$HOME_DIR/.oh-my-zsh" -c user.email=t@t -c user.name=t commit -qm init

    local p
    for p in zsh-autosuggestions zsh-syntax-highlighting; do
        mkdir -p "$HOME_DIR/.oh-my-zsh/plugins/$p"
        echo x > "$HOME_DIR/.oh-my-zsh/plugins/$p/x"
    done
    mkdir -p "$HOME_DIR/.oh-my-zsh/themes/spaceship-prompt"
    echo t > "$HOME_DIR/.oh-my-zsh/themes/spaceship-prompt/spaceship.zsh-theme"
    ln -s "$HOME_DIR/.oh-my-zsh/themes/spaceship-prompt/spaceship.zsh-theme" \
        "$HOME_DIR/.oh-my-zsh/themes/spaceship.zsh-theme"
}

make_home

# --- CLI basics ---
run_noinput "$INSTALL" list
assert_rc 0 "$RC" "list exits 0"
assert_contains "ozsh" "$OUT" "list shows ozsh"
assert_contains "git" "$OUT" "list shows git"
PLAIN="$(strip_ansi "$OUT")"
assert_contains "1 - ozsh" "$PLAIN" "ozsh is menu item 1"
assert_contains "2 - git" "$PLAIN" "git is menu item 2"

run_noinput "$INSTALL" --help
assert_rc 0 "$RC" "help exits 0"
assert_contains "doctor" "$OUT" "help mentions doctor"

run_noinput "$INSTALL" frobnicate
assert_rc 1 "$RC" "unknown command exits 1"

run_noinput "$INSTALL" install bogus
assert_rc 1 "$RC" "install of unknown component exits 1"

run_noinput "$INSTALL" -q install bogus
assert_rc 1 "$RC" "quiet install of unknown component still fails"

run_noinput "$INSTALL" doctor
assert_rc 1 "$RC" "doctor reports issues on a bare sandbox"

# --- dry run must not mutate anything ---
run_noinput "$INSTALL" --dry-run install ozsh
assert_rc 0 "$RC" "dry-run install exits 0"
assert_contains "[dry-run]" "$OUT" "dry-run announces itself"
assert_contains "(dry-run)" "$OUT" "dry-run success banner notes preview"
assert_absent "$HOME_DIR/.zshrc" "dry-run does not write .zshrc"

# --- install migrates legacy clones into custom/ ---
run_noinput "$INSTALL" install ozsh
assert_rc 0 "$RC" "install ozsh exits 0"
assert_exists "$HOME_DIR/.zshrc" "install writes .zshrc"
assert_exists "$HOME_DIR/.zshrc.local" "install writes .zshrc.local"
assert_exists "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "autosuggestions moved to custom"
assert_exists "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "syntax-highlighting moved to custom"
assert_absent "$HOME_DIR/.oh-my-zsh/plugins/zsh-autosuggestions" "legacy autosuggestions removed from checkout"
assert_exists "$HOME_DIR/.oh-my-zsh/custom/themes/spaceship.zsh-theme" "spaceship symlink created in custom"

if [ -z "$(git -C "$HOME_DIR/.oh-my-zsh" status --porcelain)" ]; then
    pass "Oh My Zsh checkout stays clean"
else
    fail "Oh My Zsh checkout is dirty"
fi

# --- idempotent re-run and doctor ---
run_noinput "$INSTALL" install ozsh
assert_rc 0 "$RC" "re-install exits 0"
run_noinput "$REPO_DIR/ozsh/scripts/doctor.sh"
assert_rc 0 "$RC" "ozsh doctor passes after install"

# --- git component ---
run_noinput "$INSTALL" install git
assert_rc 0 "$RC" "install git exits 0"
assert_exists "$HOME_DIR/.gitconfig" "gitconfig installed"
assert_exists "$HOME_DIR/.gitconfig.local" "gitconfig.local installed"
assert_exists "$HOME_DIR/.gitignore_global" "global gitignore installed"
run_noinput "$INSTALL" doctor
assert_rc 0 "$RC" "doctor passes with git installed"
PLAIN="$(strip_ansi "$OUT")"
assert_contains "== git ==" "$PLAIN" "doctor reports the git component"

# --- remove keeps files the user declines to delete ---
run $'y\nn\nn\nn\nn\nn\n' "$INSTALL" remove ozsh
assert_rc 0 "$RC" "remove ozsh exits 0"
assert_absent "$HOME_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "remove deletes custom plugin"
assert_exists "$HOME_DIR/.oh-my-zsh" "remove keeps Oh My Zsh dir by default"
assert_exists "$HOME_DIR/.zshrc.local" "remove keeps .zshrc.local when declined"

# --- remove git keeps files the user declines to delete ---
run $'y\nn\nn\nn\n' "$INSTALL" remove git
assert_rc 0 "$RC" "remove git exits 0"
assert_exists "$HOME_DIR/.gitconfig" "remove git keeps .gitconfig when declined"
assert_exists "$HOME_DIR/.gitconfig.local" "remove git keeps .gitconfig.local when declined"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
