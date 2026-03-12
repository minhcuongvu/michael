#!/usr/bin/env bash
# init.sh - Add z alias for zellij

ALIAS_LINE="alias z='zellij'"

add_alias() {
    local rc="$1"
    if [ -f "$rc" ]; then
        if grep -q "alias z=" "$rc"; then
            echo "z alias already exists in $rc"
        else
            echo "$ALIAS_LINE" >> "$rc"
            echo "Added z alias to $rc"
        fi
    fi
}

add_alias "$HOME/.bashrc"
add_alias "$HOME/.zshrc"

echo "Done. Restart your shell or run: source ~/.bashrc"
