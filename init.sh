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
                # Try native Windows symlink (requires Developer Mode or admin)
                if MSYS=winsymlinks:native ln -s "$src" "$dst" 2>/dev/null; then
                    echo "Linked $dst -> $src"
                else
                    echo "WARNING: Could not create symlink for $name (enable Developer Mode or run as admin)"
                    echo "  Copying file instead: $dst"
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

CLAUDE_CODE_SNIPPET='
# Claude Code (~/.local/bin — native binary, independent of Node)
# On MSYS2, claude install may use either $HOME or $USERPROFILE
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    for _d in "$HOME/.local/bin" "$(cygpath -u "$USERPROFILE")/.local/bin"; do
        [[ -d "$_d" ]] && case ":$PATH:" in *:"$_d":*) ;; *) export PATH="$_d:$PATH" ;; esac
    done
    unset _d
else
    [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
fi
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

add_to_rc() {
    local rc="$1"
    [[ ! -f "$rc" ]] && touch "$rc"

    ensure_snippet "$rc" "cargo PATH"       '_cargo_bin'     "$CARGO_PATH_SNIPPET"
    ensure_snippet "$rc" "opencode PATH"    '\.opencode/bin' "$OPENCODE_SNIPPET"
    ensure_snippet "$rc" "zellij config"    'ZELLIJ_CONFIG_DIR' "$ZELLIJ_SNIPPET"
    ensure_snippet "$rc" "aliases"          'alias l='       "$ALIASES_SNIPPET"
    ensure_snippet "$rc" "fnm"              'fnm env'        "$FNM_SNIPPET"
    ensure_snippet "$rc" "fzf"              'fzf --bash'     "$FZF_SNIPPET"
    ensure_snippet "$rc" "dotnet PATH"      '/c/Program Files/dotnet' "$DOTNET_SNIPPET"
    ensure_snippet "$rc" "Azure CLI PATH"   '/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin' "$AZURE_CLI_SNIPPET"
    ensure_snippet "$rc" "Claude Code PATH" '\.local/bin'    "$CLAUDE_CODE_SNIPPET"
    ensure_snippet "$rc" "git prompt"       '_git_prompt'    "$GIT_PROMPT_SNIPPET"
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
    local nvim_data
    if is_windows; then
        # Use cloud-nvim-data as configured in the nvim setup
        nvim_data="$(win_home)/AppData/Local/cloud-nvim-data"
    else
        nvim_data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
    fi

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

# ── Claude Code ─────────────────────────────────────────────────────────────

install_claude_code() {
    if command -v claude &>/dev/null; then
        echo "Claude Code already installed ($(claude --version 2>/dev/null || echo 'unknown version'))"
        return
    fi

    if ! command -v npm &>/dev/null; then
        echo "npm not found — skipping Claude Code install (install Node/fnm first)"
        return
    fi

    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code && claude install
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
if is_windows; then
    link_config "$SCRIPT_DIR/wezterm.lua" "$(win_home)/.wezterm.lua"       "wezterm"
    link_config "/c/dev/cloud-nvim"       "$(win_home)/AppData/Local/nvim" "nvim"
else
    link_config "$SCRIPT_DIR/wezterm.lua" "$HOME/.wezterm.lua" "wezterm"
    link_config "/c/dev/cloud-nvim"       "$HOME/.config/nvim" "nvim"
fi
link_config "$SCRIPT_DIR/config.kdl" "$HOME/.config/zellij/config.kdl" "zellij"

patch_nvim_plugins
install_opencode_skill
install_claude_code

echo "Done. Restart your shell or run: source ~/.bashrc"
