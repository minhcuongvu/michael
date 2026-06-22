#!/usr/bin/env bash
# init.sh — set up shell environment (bash, wezterm, zellij, nvim)
# Works on Windows (MSYS2/UCRT64) and Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ──────────────────────────────────────────────────────────────────

is_windows() {
    [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "${MSYSTEM:-}" ]]
}

win_home() { cygpath -u "$USERPROFILE"; }

# Append a snippet to an rc file if the grep pattern isn't already present.
#   ensure_snippet <rc_file> <label> <grep_pattern> <content>
ensure_snippet() {
    local rc="$1" label="$2" pattern="$3" content="$4"
    if grep -q "^[^#]*$pattern" "$rc"; then
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

    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        echo "$name symlink already exists at $dst"
    elif [[ -e "$dst" ]]; then
        echo "$name config exists at $dst (not a symlink — skipping)"
        echo "  remove it and re-run to link from repo"
    else
        # On Windows, use junction for directories (works without admin)
        # For files, try native symlink (requires Dev Mode or admin)
        if is_windows; then
            local win_src="$(cygpath -w "$src")"
            local win_dst="$(cygpath -w "$dst")"
            if [[ -d "$src" ]]; then
                cmd.exe //c "mklink /J $win_dst $win_src"
                echo "Linked $dst -> $src (junction)"
            else
                # For files: try a true native symlink via mklink (needs Dev Mode/admin).
                # Avoid `MSYS=winsymlinks:native ln -s` because without privileges it
                # silently creates a junction-on-file, which native Windows apps
                # (e.g. WezTerm) can't read — error 1920.
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

# ── shell snippets ───────────────────────────────────────────────────────────

CARGO_PATH_SNIPPET='
# cargo bin (Windows native path for MSYS2)
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    _cargo_bin="$(cygpath -u "$USERPROFILE")/.cargo/bin"
else
    _cargo_bin="$HOME/.cargo/bin"
fi
[[ -d "$_cargo_bin" ]] && export PATH="$_cargo_bin:$PATH"
unset _cargo_bin
'

OPENCODE_SNIPPET='
# opencode
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"
'

ZELLIJ_SNIPPET='
# zellij config dir (Windows native binary looks in %APPDATA%, not ~/.config)
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    export ZELLIJ_CONFIG_DIR="$(cygpath -u "$USERPROFILE")/.config/zellij"
fi
'

ALIASES_SNIPPET='
# aliases
if command -v zellij &>/dev/null; then
    alias z='"'"'zellij'"'"'
    source <(zellij setup --generate-completion bash)
    complete -F _zellij z
fi
alias l='"'"'ls'"'"'
if command -v mingw32-make &>/dev/null; then alias make='"'"'mingw32-make'"'"'; fi
'

FNM_SNIPPET='
# fnm (Fast Node Manager)
if command -v fnm &>/dev/null; then
    eval "$(fnm env)"
fi
'

FZF_SNIPPET='
# fzf (fuzzy finder)
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi
'

DOTNET_SNIPPET='
# machine-wide .NET CLI
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    _dotnet_bin="/c/Program Files/dotnet"
    [[ -d "$_dotnet_bin" ]] && case ":$PATH:" in *:"$_dotnet_bin":*) ;; *) export PATH="$_dotnet_bin:$PATH" ;; esac
    unset _dotnet_bin
fi
'

AZURE_CLI_SNIPPET='
# Azure CLI (Windows installer)
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    _azure_cli_bin="/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin"
    [[ -d "$_azure_cli_bin" ]] && case ":$PATH:" in *:"$_azure_cli_bin":*) ;; *) export PATH="$_azure_cli_bin:$PATH" ;; esac
    unset _azure_cli_bin
fi
'

ZNUKE_SNIPPET='
# znuke: clear all zellij sessions — live, exited, and zombie.
#
# Use the gentler `znuke` function first for most stuck sessions.
# For completely broken state, use the more aggressive `z-nuke` command
# (installed by init.sh into ~/.local/bin).
#
# Removes:
#   1. Socket dirs under $TMP/zellij/ (live-session zombies that zellij
#      kill-session can'"'"'t reach).
#   2. session_info dirs under %LOCALAPPDATA%/Zellij[ Contributors]/cache/
#      (resurrectable/EXITED session layouts).
#
# Prefer `znuke` over `zellij kill-all-sessions` when sessions are stuck.
znuke() {
    command -v zellij >/dev/null || { echo "zellij not in PATH"; return 1; }
    yes y 2>/dev/null | zellij kill-all-sessions   >/dev/null 2>&1
    yes y 2>/dev/null | zellij delete-all-sessions >/dev/null 2>&1

    # Socket dirs (live-session zombies). Zellij honors $TMP/$TMPDIR; on MSYS2
    # this is usually /tmp (= /c/msys64/tmp), distinct from %LOCALAPPDATA%/Temp.
    local _tmp_candidates=("${TMPDIR:-}" "${TMP:-}" "${TEMP:-}" /tmp /c/msys64/tmp)
    if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
        [[ -n "${LOCALAPPDATA:-}" ]] && _tmp_candidates+=("$(cygpath -u "$LOCALAPPDATA")/Temp")
    fi
    local _seen=" " _d
    for _d in "${_tmp_candidates[@]}"; do
        [[ -z "$_d" || "$_seen" == *" $_d "* ]] && continue
        _seen+="$_d "
        rm -rf "$_d/zellij/contract_version_"*"/" 2>/dev/null
    done

    # Resurrectable session layouts (Windows AppData; both org strings).
    if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
        local _u; _u="$(cygpath -u "${USERPROFILE:-}")"
        rm -rf "$_u/AppData/Local/Zellij/cache"/*/session_info/* \
               "$_u/AppData/Local/Zellij Contributors/Zellij/cache"/*/session_info/* \
               2>/dev/null
    fi

    local remaining; remaining=$(zellij list-sessions 2>&1)
    if [[ "$remaining" == *"No active"* || -z "$remaining" ]]; then
        echo "znuke: all sessions cleared"
    else
        echo "znuke: still present:"; echo "$remaining"
    fi
}
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

# ── bashrc / zshrc ───────────────────────────────────────────────────────────

remove_znuke_function() {
    local rc="$1"
    [[ -f "$rc" ]] || return 0
    grep -q '^znuke()' "$rc" || return 0
    # Strip the comment header (lines starting with `# znuke` until a blank line)
    # and the function body (`znuke() { ... }` ending with a `}` at column 0).
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

add_to_rc() {
    local rc="$1"
    [[ ! -f "$rc" ]] && touch "$rc"

    remove_znuke_function "$rc"

    ensure_snippet "$rc" "cargo PATH"       '_cargo_bin'     "$CARGO_PATH_SNIPPET"
    ensure_snippet "$rc" "opencode PATH"    '\.opencode/bin' "$OPENCODE_SNIPPET"
    ensure_snippet "$rc" "zellij config"    'ZELLIJ_CONFIG_DIR' "$ZELLIJ_SNIPPET"
    ensure_snippet "$rc" "aliases"          'alias l='       "$ALIASES_SNIPPET"
    ensure_snippet "$rc" "fnm"              'fnm env'        "$FNM_SNIPPET"
    ensure_snippet "$rc" "fzf"              'fzf --bash'     "$FZF_SNIPPET"
    ensure_snippet "$rc" "dotnet PATH"      '/c/Program Files/dotnet' "$DOTNET_SNIPPET"
    ensure_snippet "$rc" "Azure CLI PATH"   '/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin' "$AZURE_CLI_SNIPPET"
    ensure_snippet "$rc" "git prompt"       '_git_prompt'    "$GIT_PROMPT_SNIPPET"
    ensure_snippet "$rc" "znuke"            'znuke()'        "$ZNUKE_SNIPPET"
}

setup_bash() {
    local home="$1"

    add_to_rc "$home/.bashrc"
    [[ -f "$home/.zshrc" ]] && add_to_rc "$home/.zshrc"

    # login shells (bash --login) source .bash_profile, not .bashrc
    local bp="$home/.bash_profile"
    if [[ ! -f "$bp" ]] || ! grep -q '\.bashrc' "$bp"; then
        printf '\n[[ -f ~/.bashrc ]] && source ~/.bashrc\n' >> "$bp"
        echo "Added .bashrc source to $bp"
    else
        echo ".bash_profile already sources .bashrc"
    fi
}

# ── MSYS2 packages ──────────────────────────────────────────────────────────

install_msys2_packages() {
    local packages=(
        mingw-w64-ucrt-x86_64-ripgrep
        mingw-w64-ucrt-x86_64-jq
        mingw-w64-ucrt-x86_64-fzf
        mingw-w64-ucrt-x86_64-git-subtree
    )
    local to_install=()
    for pkg in "${packages[@]}"; do
        pacman -Qi "$pkg" &>/dev/null || to_install+=("$pkg")
    done
    if (( ${#to_install[@]} )); then
        echo "Installing MSYS2 packages: ${to_install[*]}"
        pacman -S --noconfirm "${to_install[@]}"
    else
        echo "MSYS2 packages already installed (ripgrep, jq, fzf, git-extra)"
    fi
}

# ── nvim plugin patches ─────────────────────────────────────────────────────

patch_nvim_plugins() {
    # Patches are managed by cloud-nvim's lazy.nvim build/init hooks on all
    # platforms. init.sh only applies the legacy sed patch on Windows when the
    # nvim config hasn't been linked yet (e.g. first run before :Lazy install).
    if ! is_windows; then
        return
    fi

    local nvim_data
    # Use cloud-nvim-data as configured in the nvim setup
    nvim_data="$(win_home)/AppData/Local/cloud-nvim-data"

    local target="$nvim_data/lazy/neo-tree.nvim/lua/neo-tree/git/ls-files.lua"
    if [[ ! -f "$target" ]]; then
        echo "neo-tree not installed — skipping patch"
        return
    fi

    if grep -q 'assert(vim.v.shell_error == 0)' "$target"; then
        sed -i 's/  assert(vim.v.shell_error == 0)/  if vim.v.shell_error ~= 0 then\n    return {}\n  end/' "$target"
        echo "Patched neo-tree ls-files.lua (replaced assert with graceful return)"
    else
        echo "neo-tree ls-files.lua already patched"
    fi

    # NOTE: Disabled - this patch was causing syntax errors
    # The sed replacement changes the API call incorrectly
    # # Downgrade noisy git status warning to trace (fires on Unicode path failures)
    # local git_init="$nvim_data/lazy/neo-tree.nvim/lua/neo-tree/git/init.lua"
    # if [[ -f "$git_init" ]] && grep -q 'log.at.warn.format' "$git_init" && \
    #    grep -q 'git status async process exited abnormally' "$git_init"; then
    #     sed -i '/git status async process exited abnormally/{s/log.at.warn.format/log.at.trace.format/}' "$git_init"
    #     echo "Patched neo-tree git/init.lua (downgraded async warn to trace)"
    # else
    #     echo "neo-tree git/init.lua already patched (or not found)"
    # fi
}

# ── opencode skill ──────────────────────────────────────────────────────────

install_opencode_skill() {
    local src="$SCRIPT_DIR/skill.md"
    local dst
    if is_windows; then
        dst="$(win_home)/.config/opencode/skills/michael-environment/SKILL.md"
    else
        dst="$HOME/.config/opencode/skills/michael-environment/SKILL.md"
    fi

    [[ ! -f "$src" ]] && { echo "skill.md not found in repo — skipping"; return; }

    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" ]]; then
        rm "$dst"
        ln -s "$src" "$dst"
        echo "Updated skill symlink at $dst"
    elif [[ -f "$dst" ]]; then
        if [[ ! "$dst" -ef "$src" ]]; then
            mv "$dst" "$dst.bak"
            ln -s "$src" "$dst"
            echo "Replaced skill file with symlink at $dst (backup at $dst.bak)"
        else
            echo "Skill already linked at $dst"
        fi
    else
        ln -s "$src" "$dst"
        echo "Linked skill $dst -> $src"
    fi
}

# ── opencode ────────────────────────────────────────────────────────────────

upgrade_opencode() {
    local bin
    if command -v opencode &>/dev/null; then
        bin=opencode
    elif [[ -x "$HOME/.opencode/bin/opencode" ]]; then
        bin="$HOME/.opencode/bin/opencode"
    elif is_windows && [[ -n "${USERPROFILE:-}" ]] && [[ -x "$(cygpath -u "$USERPROFILE")/.opencode/bin/opencode" ]]; then
        bin="$(cygpath -u "$USERPROFILE")/.opencode/bin/opencode"
    else
        echo "opencode not found — skipping upgrade"
        return
    fi

    echo "Upgrading opencode..."
    "$bin" upgrade
}

# ── main ─────────────────────────────────────────────────────────────────────

is_windows && install_msys2_packages

setup_bash "$HOME"

if is_windows; then
    WIN_HOME="$(win_home)"
    if [[ "$WIN_HOME" != "$HOME" ]]; then
        echo "--- Windows home ($WIN_HOME) differs from MSYS2 home ($HOME) ---"
        setup_bash "$WIN_HOME"
    fi
fi

# symlinks
NVIM_CONFIG_SRC="/c/dev/cloud-nvim"
if is_windows; then
    link_config "$SCRIPT_DIR/wezterm.lua" "$(win_home)/.wezterm.lua"       "wezterm"
    link_config "$NVIM_CONFIG_SRC"        "$(win_home)/AppData/Local/nvim" "nvim"
else
    # Linux VM / cloud instance: cloud-nvim lives in $HOME
    NVIM_CONFIG_SRC="$HOME/cloud-nvim"
    link_config "$SCRIPT_DIR/wezterm.lua" "$HOME/.wezterm.lua" "wezterm"
    link_config "$NVIM_CONFIG_SRC"      "$HOME/.config/nvim" "nvim"
fi
link_config "$SCRIPT_DIR/config.kdl" "$HOME/.config/zellij/config.kdl" "zellij"

# Install z-nuke (aggressive Zellij zombie cleaner)
# Companion to the gentler `znuke` shell function.
# Use `z-nuke` only when normal cleanup fails.
if [[ -f "$SCRIPT_DIR/z-nuke" ]]; then
    cp "$SCRIPT_DIR/z-nuke" ~/.local/bin/z-nuke
    chmod +x ~/.local/bin/z-nuke
    echo "Installed z-nuke (aggressive Zellij zombie cleaner)"
fi

patch_nvim_plugins
install_opencode_skill
upgrade_opencode

echo "Done. Restart your shell or run: source ~/.bashrc"
