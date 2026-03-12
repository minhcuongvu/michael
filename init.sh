#!/usr/bin/env bash
# init.sh - Set up z alias for zellij + git-aware prompt

# git-prompt.sh ships with git; path varies by distro
GIT_PROMPT_SNIPPET='
# git prompt
GIT_PS1_SHOWDIRTYSTATE=1
for _gp in \
    /usr/share/git/completion/git-prompt.sh \
    /usr/share/git-core/contrib/completion/git-prompt.sh \
    /etc/bash_completion.d/git-prompt; do
    [[ -f "$_gp" ]] && { source "$_gp"; break; }
done
unset _gp
export PS1='"'"'\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[36m\]$(__git_ps1 " (%s)")\[\e[0m\]\n\$ '"'"'
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

    if grep -q "GIT_PS1_SHOWDIRTYSTATE" "$rc"; then
        echo "git prompt already exists in $rc"
    else
        printf '%s\n' "$GIT_PROMPT_SNIPPET" >> "$rc"
        echo "Added git prompt to $rc"
    fi
}

add_to_rc "$HOME/.bashrc"
add_to_rc "$HOME/.zshrc"

echo "Done. Restart your shell or run: source ~/.bashrc"
