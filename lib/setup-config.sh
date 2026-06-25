#!/usr/bin/env bash
# lib/setup-config.sh — config symlinks, git, nvim, opencode, z-nuke

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_DIR="$(cd -- "${MICHAEL_REPO:-$LIB_DIR/..}" &>/dev/null && pwd)"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/helpers.sh"

setup_git() {
    local git_dir="$REPO_DIR/config/git"
    local hooks_dir="$HOME/.config/git/hooks"

    run mkdir -p "$hooks_dir"
    if [[ -f "$git_dir/hooks/prepare-commit-msg" ]]; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            echo "[DRY-RUN] would copy prepare-commit-msg to $hooks_dir/"
        else
            cp "$git_dir/hooks/prepare-commit-msg" "$hooks_dir/"
            chmod +x "$hooks_dir/prepare-commit-msg"
        fi
    fi
    if [[ -f "$git_dir/ai-attribution" ]]; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            echo "[DRY-RUN] would copy ai-attribution to $HOME/.config/git/"
        else
            cp "$git_dir/ai-attribution" "$HOME/.config/git/ai-attribution"
        fi
    fi
    link_config "$git_dir/gitconfig" "$HOME/.gitconfig" "gitconfig"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would run: git config --global core.hooksPath $hooks_dir"
    else
        git config --global core.hooksPath "$hooks_dir"
    fi
}

patch_nvim_plugins() {
    if ! is_windows; then
        return
    fi

    local nvim_data
    nvim_data="$(win_home)/AppData/Local/cloud-nvim-data"

    local target="$nvim_data/lazy/neo-tree.nvim/lua/neo-tree/git/ls-files.lua"
    if [[ ! -f "$target" ]]; then
        echo "neo-tree not installed — skipping patch"
        return
    fi

    if grep -q 'assert(vim.v.shell_error == 0)' "$target"; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            echo "[DRY-RUN] would patch neo-tree ls-files.lua (replace assert with graceful return)"
            return
        fi
        sed -i 's/  assert(vim.v.shell_error == 0)/  if vim.v.shell_error ~= 0 then\n    return {}\n  end/' "$target"
        echo "Patched neo-tree ls-files.lua (replaced assert with graceful return)"
    else
        echo "neo-tree ls-files.lua already patched"
    fi
}

install_opencode_skill() {
    local src="$REPO_DIR/skills/michael-environment/SKILL.md"
    local dst
    if is_windows; then
        dst="$(win_home)/.config/opencode/skills/michael-environment/SKILL.md"
    else
        dst="$HOME/.config/opencode/skills/michael-environment/SKILL.md"
    fi

    link_config "$src" "$dst" "opencode skill"
}

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
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would run: $bin upgrade"
        return
    fi
    "$bin" upgrade
}

setup_symlinks() {
    local nvim_config_src="$CLOUD_NVIM_REPO"
    local wezterm_src="$REPO_DIR/wezterm.lua"
    local zellij_src="$REPO_DIR/config.kdl"

    if is_windows; then
        link_config "$wezterm_src" "$(win_home)/.wezterm.lua"       "wezterm"
        link_config "$nvim_config_src" "$(win_home)/AppData/Local/nvim" "nvim"
        link_config "$zellij_src" "$(win_home)/.config/zellij/config.kdl" "zellij"
    else
        nvim_config_src="$HOME/cloud-nvim"
        link_config "$wezterm_src" "$HOME/.wezterm.lua" "wezterm"
        link_config "$nvim_config_src" "$HOME/.config/nvim" "nvim"
        link_config "$zellij_src" "$HOME/.config/zellij/config.kdl" "zellij"
    fi
}

install_z_nuke() {
    local src="$REPO_DIR/z-nuke"
    [[ ! -f "$src" ]] && return

    local local_bin
    if is_windows; then local_bin="$(win_home)/.local/bin"; else local_bin="$HOME/.local/bin"; fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would copy $src to $local_bin/z-nuke"
        return
    fi

    mkdir -p "$local_bin"
    cp "$src" "$local_bin/z-nuke"
    chmod +x "$local_bin/z-nuke"
    echo "Installed z-nuke (aggressive Zellij zombie cleaner)"
}
