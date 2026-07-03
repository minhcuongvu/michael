#!/usr/bin/env bash
# init.sh — set up shell environment (bash, wezterm, zellij, nvim)
# Works on Windows (MSYS2/UCRT64) and Linux
#
# Usage:
#   bash init.sh              # normal run
#   bash init.sh --dry-run    # show what would be changed
#   bash init.sh --uninstall-zellij   # incompatible with --dry-run

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/helpers.sh"
source "$SCRIPT_DIR/lib/setup-shell.sh"
source "$SCRIPT_DIR/lib/setup-tools.sh"
source "$SCRIPT_DIR/lib/setup-config.sh"
source "$SCRIPT_DIR/lib/uninstall.sh"

# ── argument parsing ─────────────────────────────────────────────────────────

DRY_RUN=0
UNINSTALL_ZELLIJ=0

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --uninstall-zellij) UNINSTALL_ZELLIJ=1 ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--dry-run] [--uninstall-zellij]"
            exit 1
            ;;
    esac
done

if [[ "$DRY_RUN" == "1" && "$UNINSTALL_ZELLIJ" == "1" ]]; then
    echo "Error: --dry-run and --uninstall-zellij cannot be used together"
    exit 1
fi

export DRY_RUN

if [[ "$UNINSTALL_ZELLIJ" == "1" ]]; then
    uninstall_zellij
    exit 0
fi

if [[ "$DRY_RUN" == "1" ]]; then
    echo "=== DRY RUN — no changes will be made ==="
fi

# ── main orchestration ───────────────────────────────────────────────────────

is_windows && install_msys2_packages
is_windows && install_zellij
install_grok

setup_bash "$HOME"
setup_git

if is_windows; then
    WIN_HOME="$(win_home)"
    if [[ "$WIN_HOME" != "$HOME" ]]; then
        echo "--- Windows home ($WIN_HOME) differs from MSYS2 home ($HOME) ---"
        setup_bash "$WIN_HOME"
    fi
    sync_extra_windows_profiles "$WIN_HOME/.bashrc"
fi

setup_symlinks
install_z_nuke
patch_nvim_plugins
install_opencode_skill
upgrade_opencode
upgrade_grok
upgrade_claude

if [[ "$DRY_RUN" == "1" ]]; then
    echo "=== DRY RUN complete — no changes were made ==="
else
    echo "Done. Restart your shell or run: source ~/.bashrc"
fi
