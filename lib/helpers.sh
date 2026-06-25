#!/usr/bin/env bash
# lib/helpers.sh — shared utility functions

is_windows() {
    [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "${MSYSTEM:-}" ]]
}

win_home() { cygpath -u "$USERPROFILE"; }

# Run a command, or print it in dry-run mode.
run() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

# Append a snippet to an rc file if the grep pattern isn't already present.
#   ensure_snippet <rc_file> <label> <grep_pattern> <content> [fixed]
# Pass "fixed" as the 5th arg to use grep -F (literal match) instead of BRE.
ensure_snippet() {
    local rc="$1" label="$2" pattern="$3" content="$4" fixed="${5:-}"
    local present=1

    if [[ -f "$rc" ]]; then
        if [[ "$fixed" == "fixed" ]]; then
            grep -Fq "$pattern" "$rc" 2>/dev/null || present=0
        else
            grep -q "^[^#]*$pattern" "$rc" 2>/dev/null || present=0
        fi
    else
        present=0
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        if (( present )); then
            echo "[DRY-RUN] $label already in $rc"
        else
            echo "[DRY-RUN] would add $label to $rc"
        fi
        return
    fi

    if (( present )); then
        echo "$label already in $rc"
    else
        printf '%s\n' "$content" >> "$rc"
        echo "Added $label to $rc"
    fi
}

# Create a symlink (or junction on Windows), skipping if the target already exists.
#   link_config <src> <dst> <name>
link_config() {
    local src="$1" dst="$2" name="$3"

    if [[ ! -e "$src" ]]; then
        echo "$name not found at $src — skipping"
        return
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        if [[ -L "$dst" ]]; then
            echo "[DRY-RUN] $name symlink already exists at $dst"
        elif [[ -e "$dst" ]]; then
            echo "[DRY-RUN] $name config exists at $dst (not a symlink — would skip)"
        else
            echo "[DRY-RUN] would link $dst -> $src ($name)"
        fi
        return
    fi

    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        echo "$name symlink already exists at $dst"
    elif [[ -e "$dst" ]]; then
        echo "$name config exists at $dst (not a symlink — skipping)"
        echo "  remove it and re-run to link from repo"
    else
        if is_windows; then
            local win_src="$(cygpath -w "$src")"
            local win_dst="$(cygpath -w "$dst")"
            if [[ -d "$src" ]]; then
                cmd.exe //c "mklink /J $win_dst $win_src"
                echo "Linked $dst -> $src (junction)"
            else
                if cmd.exe //c "mklink $win_dst $win_src" >/dev/null 2>&1; then
                    echo "Linked $dst -> $src (native symlink)"
                else
                    echo "Note: no symlink privilege for $name — copying file instead"
                    cp "$src" "$dst"
                fi
            fi
        else
            ln -s "$src" "$dst"
            echo "Linked $dst -> $src"
        fi
    fi
}

# Strip a single top-level `if … fi` block that starts with a matching comment header.
remove_if_fi_block() {
    local rc="$1" header_re="$2"
    [[ -f "$rc" ]] || return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        grep -q "$header_re" "$rc" 2>/dev/null && echo "[DRY-RUN] would remove block matching $header_re from $rc"
        return 0
    fi
    awk -v re="$header_re" '
        $0 ~ re { skip=1; depth=0; next }
        skip {
            if ($0 ~ /^[[:space:]]*if / || $0 ~ /^if /) depth++
            if ($0 ~ /^[[:space:]]*fi[[:space:]]*$/ || $0 ~ /^fi[[:space:]]*$/) {
                if (depth > 0) { depth--; next }
                skip=0; next
            }
            next
        }
        { print }
    ' "$rc" > "$rc.cleanup.tmp" && mv "$rc.cleanup.tmp" "$rc"
}

remove_user_tmp_block() {
    remove_if_fi_block "$1" '^# Per-user temp'
}

remove_aliases_block() {
    local rc="$1"
    [[ -f "$rc" ]] || return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        grep -q '^# aliases' "$rc" 2>/dev/null && echo "[DRY-RUN] would remove aliases block from $rc"
        return 0
    fi
    awk '
        /^# aliases/ { skip=1; next }
        skip && /^# [A-Za-z]/ { skip=0; print; next }
        skip { next }
        { print }
    ' "$rc" > "$rc.aliases.tmp" && mv "$rc.aliases.tmp" "$rc"
}

remove_zellij_wrapper_block() {
    local rc="$1"
    [[ -f "$rc" ]] || return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        grep -q '^# zellij wrapper' "$rc" 2>/dev/null && echo "[DRY-RUN] would remove zellij wrapper block from $rc"
        return 0
    fi
    awk '
        /^# zellij wrapper/ { skip=1; depth=0; next }
        skip {
            if ($0 ~ /^[[:space:]]*if / || $0 ~ /^if /) depth++
            if ($0 ~ /^[[:space:]]*fi[[:space:]]*$/ || $0 ~ /^fi[[:space:]]*$/) {
                if (depth > 0) { depth--; next }
                skip=0; next
            }
            next
        }
        { print }
    ' "$rc" > "$rc.wrapper.tmp" && mv "$rc.wrapper.tmp" "$rc"
}

remove_znuke_function() {
    local rc="$1"
    [[ -f "$rc" ]] || return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        grep -q '^znuke()' "$rc" 2>/dev/null && echo "[DRY-RUN] would remove znuke function from $rc"
        return 0
    fi
    grep -q '^znuke()' "$rc" || return 0
    awk '
        /^# znuke:/ { in_hdr=1; next }
        in_hdr && /^[[:space:]]*$/ { in_hdr=0; next }
        in_hdr && /^#/ { next }
        in_hdr { in_hdr=0 }
        /^znuke\(\)/ { in_fn=1 }
        in_fn { if ($0 ~ /^\}$/) { in_fn=0; next } else next }
        { print }
    ' "$rc" > "$rc.znuke.tmp" && mv "$rc.znuke.tmp" "$rc"
}

purge_zellij_from_rc() {
    local rc="$1"
    [[ -f "$rc" ]] || return 0
    grep -qiE 'zellij|znuke|ZELLIJ' "$rc" || return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would purge zellij blocks from $rc"
        return 0
    fi
    echo "Removing zellij from $rc"
    remove_zellij_wrapper_block "$rc"
    remove_if_fi_block "$rc" '^# zellij MSI install'
    remove_if_fi_block "$rc" '^# zellij config dir'
    remove_user_tmp_block "$rc"
    remove_if_fi_block "$rc" '^# Shared temp for zellij'
    remove_if_fi_block "$rc" '^# Shared zellij session'
    remove_aliases_block "$rc"
    remove_znuke_function "$rc"
}
