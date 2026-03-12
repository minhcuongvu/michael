#!/usr/bin/env bash
# init.sh - Set up shell environment (bash/zsh, wezterm)
# Works on Windows (MSYS2/UCRT64) and Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── snippets ──────────────────────────────────────────────────────────────────

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

    if grep -q "alias z=" "$rc" || grep -q "alias l=" "$rc"; then
        echo "aliases already in $rc"
    else
        printf '%s\n' "$ALIASES_SNIPPET" >> "$rc"
        echo "Added aliases to $rc"
    fi

    if grep -q "_git_prompt" "$rc"; then
        echo "git prompt already in $rc"
    else
        printf '%s\n' "$GIT_PROMPT_SNIPPET" >> "$rc"
        echo "Added git prompt to $rc"
    fi
}

add_to_rc "$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && add_to_rc "$HOME/.zshrc"

# login shells (bash --login) source .bash_profile, not .bashrc
# make sure .bash_profile sources .bashrc so our setup actually loads
BASH_PROFILE="$HOME/.bash_profile"
if [[ ! -f "$BASH_PROFILE" ]] || ! grep -q '\.bashrc' "$BASH_PROFILE"; then
    printf '\n[[ -f ~/.bashrc ]] && source ~/.bashrc\n' >> "$BASH_PROFILE"
    echo "Added .bashrc source to $BASH_PROFILE"
else
    echo ".bash_profile already sources .bashrc"
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

echo "Done. Restart your shell or run: source ~/.bashrc"
