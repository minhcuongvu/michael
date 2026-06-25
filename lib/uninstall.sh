#!/usr/bin/env bash
# lib/uninstall.sh — zellij uninstall and cleanup

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$LIB_DIR/config.sh"
REPO_DIR="$(cd -- "${MICHAEL_REPO:-$LIB_DIR/..}" &>/dev/null && pwd)"
source "$LIB_DIR/helpers.sh"
source "$LIB_DIR/setup-shell.sh"

uninstall_zellij_data() {
    local base
    for base in "${@:-}"; do
        [[ -z "$base" ]] && continue
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            echo "[DRY-RUN] would remove zellij data under $base"
            continue
        fi
        rm -rf "$base/AppData/Local/Zellij" "$base/AppData/Local/Zellij Contributors" 2>/dev/null
        rm -rf "$base/.config/zellij" 2>/dev/null
        rm -f "$base/.local/bin/z-nuke" 2>/dev/null
        rm -rf "$base/.cache/zellij" "$base/.local/share/zellij" "$base/.local/state/zellij" 2>/dev/null
        rm -f "$base/.cargo/bin/zellij" 2>/dev/null
    done
}

uninstall_zellij() {
    echo "=== Uninstalling zellij ==="

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would kill zellij processes"
    else
        pkill -9 zellij 2>/dev/null || true
    fi

    if is_windows && command -v powershell.exe &>/dev/null; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            echo "[DRY-RUN] would uninstall Zellij MSI and remove Zellij from PATH"
        else
            powershell.exe -NoProfile -Command \
                "Get-Package -Name 'Zellij' -ErrorAction SilentlyContinue | Uninstall-Package -Force" \
                2>/dev/null || true
            powershell.exe -NoProfile -Command \
                'foreach ($scope in "User","Machine") { $p = [Environment]::GetEnvironmentVariable("Path", $scope); if ($p -and $p -match "Zellij") { $np = ($p -split ";" | Where-Object { $_ -notmatch "Zellij" }) -join ";"; [Environment]::SetEnvironmentVariable("Path", $np, $scope) } }' \
                2>/dev/null || true
        fi
    fi

    local homes=("$HOME")
    is_windows && homes+=("$(win_home)")
    for h in /c/Users/*/; do
        [[ -r "$h" && -f "${h}.bashrc" ]] && homes+=("${h%/}")
    done
    local seen=" " h
    for h in "${homes[@]}"; do
        [[ -z "$h" || "$seen" == *" $h "* ]] && continue
        seen+=" $h "
        uninstall_zellij_data "$h"
        purge_zellij_from_rc "$h/.bashrc"
        [[ -f "$h/.zshrc" ]] && purge_zellij_from_rc "$h/.zshrc"
    done

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "[DRY-RUN] would remove shared zellij temp dirs"
    else
        rm -rf "$REPO_DIR/.zellij-shared" /tmp/zellij /c/msys64/tmp/zellij 2>/dev/null
        for t in /c/Users/*/AppData/Local/Temp/zellij; do
            [[ -e "$t" || -L "$t" ]] && rm -rf "$t"
        done
    fi

    # Re-apply non-zellij shell snippets after purge.
    export SKIP_ZELLIJ=1
    setup_bash "$HOME"
    if is_windows; then
        local wh; wh="$(win_home)"
        [[ "$wh" != "$HOME" ]] && setup_bash "$wh"
        sync_extra_windows_profiles "$wh/.bashrc"
    fi
    unset SKIP_ZELLIJ

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "=== DRY RUN complete — no changes were made ==="
    else
        echo "Zellij removed. Restart your shell or run: source ~/.bashrc"
    fi
}
