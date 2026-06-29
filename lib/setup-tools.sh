#!/usr/bin/env bash
# lib/setup-tools.sh — MSYS2 packages, zellij, and grok installation

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/helpers.sh"

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
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            echo "[DRY-RUN] would run: pacman -S --noconfirm ${to_install[*]}"
        else
            pacman -S --noconfirm "${to_install[@]}"
        fi
    else
        echo "MSYS2 packages already installed (ripgrep, jq, fzf, git-extra)"
    fi
}

install_zellij() {
    if ! is_windows; then
        command -v zellij &>/dev/null && echo "zellij already in PATH" && return
        echo "zellij not found — install via your distro package manager"
        return
    fi

    local zellij_exe
    zellij_exe="$(cygpath -u "$LOCALAPPDATA")/Zellij/zellij.exe"
    if [[ -x "$zellij_exe" ]]; then
        echo "zellij already installed at $zellij_exe ($("$zellij_exe" --version))"
        return
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would download zellij $ZELLIJ_VERSION MSI from $ZELLIJ_MSI_URL"
        echo "[DRY-RUN] would run: msiexec //i <msi> //quiet //norestart"
        return
    fi

    if ! command -v curl &>/dev/null; then
        echo "zellij not found — need curl to download the Windows MSI"
        return
    fi

    local tmpdir msi win_msi
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' RETURN
    msi="$tmpdir/zellij-installer.msi"
    echo "Installing zellij $ZELLIJ_VERSION MSI..."
    curl -fsSLo "$msi" "$ZELLIJ_MSI_URL"
    win_msi="$(cygpath -w "$msi")"

    msiexec //i "$win_msi" //quiet //norestart
    local i
    for i in $(seq 1 30); do
        [[ -x "$zellij_exe" ]] && break
        sleep 1
    done
    if [[ -x "$zellij_exe" ]]; then
        echo "Installed zellij $("$zellij_exe" --version)"
    else
        echo "zellij MSI install may still be running — restart shell and re-run init.sh"
    fi
}

install_grok() {
    if command -v grok &>/dev/null; then
        echo "grok already in PATH"
        return
    fi
    if [[ -x "$HOME/.grok/bin/grok" ]]; then
        echo "grok already installed at $HOME/.grok/bin/grok"
        return
    fi
    if is_windows && [[ -n "${USERPROFILE:-}" ]]; then
        local win_grok
        win_grok="$(cygpath -u "$USERPROFILE")/.grok/bin/grok"
        if [[ -x "$win_grok" ]]; then
            echo "grok already installed at $win_grok"
            return
        fi
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would run: curl -fsSL https://x.ai/cli/install.sh | bash"
        return
    fi

    if ! command -v curl &>/dev/null; then
        echo "grok not found — need curl to install"
        return
    fi

    echo "Installing grok..."
    curl -fsSL https://x.ai/cli/install.sh | bash
}

upgrade_grok() {
    local bin
    if command -v grok &>/dev/null; then
        bin=grok
    elif [[ -x "$HOME/.grok/bin/grok" ]]; then
        bin="$HOME/.grok/bin/grok"
    elif is_windows && [[ -n "${USERPROFILE:-}" ]] && [[ -x "$(cygpath -u "$USERPROFILE")/.grok/bin/grok" ]]; then
        bin="$(cygpath -u "$USERPROFILE")/.grok/bin/grok"
    else
        echo "grok not found — skipping upgrade"
        return
    fi

    echo "Upgrading grok ($("$bin" --version 2>/dev/null || echo unknown))..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would run: curl -fsSL https://x.ai/cli/install.sh | bash"
        return
    fi

    if ! command -v curl &>/dev/null; then
        echo "grok upgrade needs curl"
        return
    fi

    curl -fsSL https://x.ai/cli/install.sh | bash
}
