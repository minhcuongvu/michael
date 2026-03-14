#!/usr/bin/env bash
# init.sh - Set up shell environment (bash/zsh, wezterm)
# Works on Windows (MSYS2/UCRT64) and Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── snippets ──────────────────────────────────────────────────────────────────

CARGO_SNIPPET_UNIX='
# cargo
export PATH="$HOME/.cargo/bin:$PATH"
'

# On MSYS2, $HOME may be /home/User but cargo installs to the Windows
# profile (C:/Users/User).  Use /c/Users/$USER so the path is always correct.
CARGO_SNIPPET_WIN='
# cargo (resolve Windows home — cargo installs there, not in MSYS2 home)
export PATH="/c/Users/$USER/.cargo/bin:$PATH"
'

if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
    CARGO_SNIPPET="$CARGO_SNIPPET_WIN"
else
    CARGO_SNIPPET="$CARGO_SNIPPET_UNIX"
fi

ALIASES_SNIPPET='
# aliases
if command -v zellij &>/dev/null; then
    alias z='"'"'zellij'"'"'
    source <(zellij setup --generate-completion bash)
    complete -F _zellij z
fi
alias l='"'"'ls'"'"'
'

GIT_PROMPT_SNIPPET='
# git prompt
_git_prompt() {
    local b dirty
    b=$(git symbolic-ref --short HEAD 2>/dev/null) || { GIT_INFO='"'"''"'"'; return; }
    [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty='"'"' *'"'"'
    GIT_INFO=" (${b}${dirty})"
}
PROMPT_COMMAND='"'"'_git_prompt'"'"'
export PS1='"'"'\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[36m\]${GIT_INFO}\[\e[0m\]\n\$ '"'"'
'

# ── bashrc / zshrc ────────────────────────────────────────────────────────────

add_to_rc() {
    local rc="$1"
    [[ ! -f "$rc" ]] && touch "$rc"

    if grep -q 'cargo/bin' "$rc"; then
        echo "cargo PATH already in $rc"
    else
        printf '%s\n' "$CARGO_SNIPPET" >> "$rc"
        echo "Added cargo PATH to $rc"
    fi

    if grep -q '^[^#]*alias z=' "$rc" || grep -q '^[^#]*alias l=' "$rc"; then
        echo "aliases already in $rc"
    else
        printf '%s\n' "$ALIASES_SNIPPET" >> "$rc"
        echo "Added aliases to $rc"
    fi

    if grep -q '^[^#]*_git_prompt' "$rc"; then
        echo "git prompt already in $rc"
    else
        printf '%s\n' "$GIT_PROMPT_SNIPPET" >> "$rc"
        echo "Added git prompt to $rc"
    fi
}

setup_bash() {
    local home="$1"

    add_to_rc "$home/.bashrc"
    [[ -f "$home/.zshrc" ]] && add_to_rc "$home/.zshrc"

    # login shells (bash --login) source .bash_profile, not .bashrc
    # make sure .bash_profile sources .bashrc so our setup actually loads
    local bp="$home/.bash_profile"
    if [[ ! -f "$bp" ]] || ! grep -q '\.bashrc' "$bp"; then
        printf '\n[[ -f ~/.bashrc ]] && source ~/.bashrc\n' >> "$bp"
        echo "Added .bashrc source to $bp"
    else
        echo ".bash_profile already sources .bashrc"
    fi
}

setup_bash "$HOME"

# On MSYS2/UCRT64, wezterm uses CHERE_INVOKING=1 which sets HOME to the
# Windows user profile instead of the MSYS2 home. Write to both so the
# shell config works regardless of how bash is launched.
if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
    WIN_HOME="$(cygpath -u "$USERPROFILE")"
    if [[ "$WIN_HOME" != "$HOME" ]]; then
        echo "--- Windows home ($WIN_HOME) differs from MSYS2 home ($HOME) ---"
        setup_bash "$WIN_HOME"
    fi
fi

# ── wezterm ───────────────────────────────────────────────────────────────────

link_wezterm() {
    local src="$SCRIPT_DIR/wezterm.lua"
    local dst

    if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
        # Windows (MSYS2) — convert to Windows path for symlink
        dst="$(cygpath -u "$USERPROFILE")/.wezterm.lua"
    else
        dst="$HOME/.wezterm.lua"
    fi

    if [[ ! -f "$src" ]]; then
        echo "wezterm.lua not found in repo — skipping"
        return
    fi

    if [[ -L "$dst" ]]; then
        echo "wezterm symlink already exists at $dst"
    elif [[ -f "$dst" ]]; then
        echo "wezterm config exists at $dst (not a symlink — skipping)"
        echo "  remove it and re-run to link from repo"
    else
        ln -s "$src" "$dst"
        echo "Linked $dst -> $src"
    fi
}

link_wezterm

# ── zellij ───────────────────────────────────────────────────────────────────

link_zellij() {
    local src="$SCRIPT_DIR/config.kdl"
    local dst

    if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
        # MSYS2: zellij reads from Windows home, not /home/User
        dst="$(cygpath -u "$USERPROFILE")/.config/zellij/config.kdl"
    else
        dst="$HOME/.config/zellij/config.kdl"
    fi

    if [[ ! -f "$src" ]]; then
        echo "config.kdl not found in repo — skipping zellij"
        return
    fi

    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        echo "zellij symlink already exists at $dst"
    elif [[ -f "$dst" ]]; then
        echo "zellij config exists at $dst (not a symlink — skipping)"
        echo "  remove it and re-run to link from repo"
    else
        ln -s "$src" "$dst"
        echo "Linked $dst -> $src"
    fi
}

link_zellij

echo "Done. Restart your shell or run: source ~/.bashrc"
