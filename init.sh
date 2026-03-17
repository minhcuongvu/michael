#!/usr/bin/env bash
# init.sh - Set up shell environment (bash/zsh, wezterm)
# Works on Windows (MSYS2/UCRT64) and Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── snippets ──────────────────────────────────────────────────────────────────

CARGO_SNIPPET_UNIX='
# cargo
export PATH="$HOME/.cargo/bin:$PATH"
'

# On MSYS2/Windows, MSYS2 minimal PATH strips most Windows directories.
# Add them back explicitly so tools work from any shell (WezTerm, Claude Code, etc).
WIN_TOOLS_SNIPPET='
# Windows tools (MSYS2 minimal PATH strips these)
export PATH="/c/Users/$USER/.cargo/bin:$PATH"                    # cargo
export PATH="/c/Program Files/Docker/Docker/resources/bin:$PATH" # Docker Desktop
export PATH="/c/Program Files/Go/bin:$PATH"                      # Go
export PATH="/c/Users/$USER/go/bin:$PATH"                        # Go GOPATH/bin
export PATH="/c/Dev/opencode:$PATH"                              # opencode
'

if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
    CARGO_SNIPPET="$WIN_TOOLS_SNIPPET"
else
    CARGO_SNIPPET="$CARGO_SNIPPET_UNIX"
fi

OPENCODE_SNIPPET='
# opencode
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"
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
        echo "tool PATHs already in $rc"
    else
        printf '%s\n' "$CARGO_SNIPPET" >> "$rc"
        echo "Added tool PATHs to $rc"
    fi

    if grep -q '^[^#]*\.opencode/bin' "$rc"; then
        echo "opencode PATH already in $rc"
    else
        printf '%s\n' "$OPENCODE_SNIPPET" >> "$rc"
        echo "Added opencode PATH to $rc"
    fi

    if grep -q '^[^#]*alias z=' "$rc" || grep -q '^[^#]*alias l=' "$rc"; then
        echo "aliases already in $rc"
    else
        printf '%s\n' "$ALIASES_SNIPPET" >> "$rc"
        echo "Added aliases to $rc"
    fi

    if grep -q '^[^#]*fnm env' "$rc"; then
        echo "fnm already in $rc"
    else
        printf '%s\n' "$FNM_SNIPPET" >> "$rc"
        echo "Added fnm to $rc"
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

# ── MSYS2 packages ────────────────────────────────────────────────────────────

install_msys2_packages() {
    local packages=(
        mingw-w64-ucrt-x86_64-ripgrep
        mingw-w64-ucrt-x86_64-jq
    )
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        echo "Installing MSYS2 packages: ${to_install[*]}"
        pacman -S --noconfirm "${to_install[@]}"
    else
        echo "MSYS2 packages already installed (ripgrep, jq)"
    fi
}

if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
    install_msys2_packages
fi

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

    dst="$HOME/.config/zellij/config.kdl"

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

# ── neovim ──────────────────────────────────────────────────────────────────

link_nvim() {
    local src="/c/dev/cloud-nvim"
    local dst

    if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
        dst="$(cygpath -u "$USERPROFILE")/AppData/Local/nvim"
    else
        dst="$HOME/.config/nvim"
    fi

    if [[ ! -d "$src" ]]; then
        echo "cloud-nvim not found at $src — skipping"
        return
    fi

    if [[ -L "$dst" ]]; then
        echo "nvim symlink already exists at $dst"
    elif [[ -d "$dst" ]]; then
        echo "nvim config exists at $dst (not a symlink — skipping)"
        echo "  remove it and re-run to link from repo"
    else
        mkdir -p "$(dirname "$dst")"
        ln -s "$src" "$dst"
        echo "Linked $dst -> $src"
    fi
}

link_nvim

# ── nvim plugin patches ─────────────────────────────────────────────────────

patch_nvim_plugins() {
    local nvim_data
    if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
        nvim_data="$(cygpath -u "$USERPROFILE")/AppData/Local/nvim-data"
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

    # Downgrade noisy git status warning to trace (fires on Unicode path failures)
    local git_init="$nvim_data/lazy/neo-tree.nvim/lua/neo-tree/git/init.lua"
    if [[ -f "$git_init" ]] && grep -q 'log.at.warn.format' "$git_init" && \
       grep -q 'git status async process exited abnormally' "$git_init"; then
        sed -i '/git status async process exited abnormally/{s/log.at.warn.format/log.at.trace.format/}' "$git_init"
        echo "Patched neo-tree git/init.lua (downgraded async warn to trace)"
    else
        echo "neo-tree git/init.lua already patched (or not found)"
    fi
}

patch_nvim_plugins

# ── opencode skills ───────────────────────────────────────────────────────────

install_opencode_skill() {
    local src="$SCRIPT_DIR/skill.md"
    local dst

    if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || -n "$MSYSTEM" ]]; then
        dst="$(cygpath -u "$USERPROFILE")/.config/opencode/skills/michael-environment/SKILL.md"
    else
        dst="$HOME/.config/opencode/skills/michael-environment/SKILL.md"
    fi

    if [[ ! -f "$src" ]]; then
        echo "skill.md not found in repo — skipping"
        return
    fi

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

install_opencode_skill

echo "Done. Restart your shell or run: source ~/.bashrc"
