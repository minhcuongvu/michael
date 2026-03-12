#!/usr/bin/env bash
# init.sh - Set up aliases + git-aware prompt

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

add_to_rc() {
    local rc="$1"
    [[ ! -f "$rc" ]] && return

    if grep -q "alias z=" "$rc" || grep -q "alias l=" "$rc"; then
        echo "aliases already exist in $rc"
    else
        printf '%s\n' "$ALIASES_SNIPPET" >> "$rc"
        echo "Added aliases to $rc"
    fi

    if grep -q "_git_prompt" "$rc"; then
        echo "git prompt already exists in $rc"
    else
        printf '%s\n' "$GIT_PROMPT_SNIPPET" >> "$rc"
        echo "Added git prompt to $rc"
    fi
}

add_to_rc "$HOME/.bashrc"
add_to_rc "$HOME/.zshrc"

echo "Done. Restart your shell or run: source ~/.bashrc"
