#!/usr/bin/env bash
# init.sh - Set up z alias for zellij + git-aware prompt

GIT_PS1_FUNC='
# git prompt
__git_ps1() {
    local branch dirty
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
    [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty=" *"
    printf " (%s%s)" "$branch" "$dirty"
}
export PS1='"'"'\[\e[32m\]\u@\h\[\e[0m\] \[\e[33m\]\w\[\e[36m\]$(__git_ps1)\[\e[0m\]\n\$ '"'"'
'

add_to_rc() {
    local rc="$1"
    [[ ! -f "$rc" ]] && return

    if grep -q "alias z=" "$rc"; then
        echo "z alias already exists in $rc"
    else
        echo "alias z='zellij'" >> "$rc"
        echo "Added z alias to $rc"
    fi

    if grep -q "__git_ps1" "$rc"; then
        echo "git prompt already exists in $rc"
    else
        echo "$GIT_PS1_FUNC" >> "$rc"
        echo "Added git prompt to $rc"
    fi
}

add_to_rc "$HOME/.bashrc"
add_to_rc "$HOME/.zshrc"

echo "Done. Restart your shell or run: source ~/.bashrc"
