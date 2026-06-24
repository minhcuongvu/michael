#!/usr/bin/env bash
# init.sh — set up shell environment (bash, wezterm, zellij, nvim)
# Works on Windows (MSYS2/UCRT64) and Linux

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

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

USER_TMP_SNIPPET='
# Per-user temp (MSYS2 defaults TMP to shared /tmp)
if [[ -n "${LOCALAPPDATA:-}" && ( -n "$MSYSTEM" || "$OSTYPE" == msys* || -n "${WINDIR:-}" ) ]]; then
    _user_tmp="$(cygpath -u "$LOCALAPPDATA")/Temp"
    [[ -L "$_user_tmp/zellij" ]] && rm -f "$_user_tmp/zellij"
    export TMPDIR="$_user_tmp"
    export TMP="$_user_tmp"
    export TEMP="$_user_tmp"
    mkdir -p "$_user_tmp"
    unset _user_tmp
fi
'

ZELLIJ_WRAPPER_SNIPPET='
# zellij wrapper — one session ("one") per Windows profile
z() {
    command -v zellij >/dev/null || { echo "zellij not in PATH"; return 1; }
    if (($# == 0)); then
        zellij attach -c one
    else
        zellij "$@"
    fi
}
'

ZELLIJ_PATH_SNIPPET='
# zellij MSI install (Windows — %LOCALAPPDATA%/Zellij)
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    _zellij_bin="$(cygpath -u "$LOCALAPPDATA")/Zellij"
    [[ -d "$_zellij_bin" ]] && case ":$PATH:" in *:"$_zellij_bin":*) ;; *) export PATH="$_zellij_bin:$PATH" ;; esac
    unset _zellij_bin
fi
'

ZELLIJ_SNIPPET='
# zellij config dir (Windows native binary looks in %APPDATA%, not ~/.config)
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    export ZELLIJ_CONFIG_DIR="$(cygpath -u "$USERPROFILE")/.config/zellij"
    mkdir -p "$ZELLIJ_CONFIG_DIR"
    [[ -n "${LOCALAPPDATA:-}" ]] && mkdir -p "$(cygpath -u "$LOCALAPPDATA")/Zellij/cache"
fi
'

ALIASES_SNIPPET='
# aliases
if command -v zellij &>/dev/null; then
    _zcomp="${TMPDIR:-/tmp}/zellij-completion-${UID:-0}.bash"
    if zellij setup --generate-completion bash >"$_zcomp" 2>/dev/null; then
        # shellcheck disable=SC1090
        source "$_zcomp"
        complete -F _zellij z 2>/dev/null
    fi
    rm -f "$_zcomp"
    unset _zcomp
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

# fzf/grok inject `alias git='"'"'/c/Program Files/Git/bin/git.exe'"'"'`, which breaks
# command substitution (spaces in path). Prefer MSYS2 git for shell use.
unalias git 2>/dev/null
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

TAILSCALE_SNIPPET='
# Tailscale CLI (MSYS2 minimal PATH omits C:\Program Files\Tailscale)
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    _tailscale_bin="/c/Program Files/Tailscale"
    [[ -d "$_tailscale_bin" ]] && case ":$PATH:" in *:"$_tailscale_bin":*) ;; *) export PATH="$_tailscale_bin:$PATH" ;; esac
    unset _tailscale_bin
fi
'

FORGEJO_SNIPPET='
# Forgejo MCP — Grok expands ${FORGEJO_TOKEN} from the environment at startup
_fj_env="$HOME/.config/forgejo/env"
if [[ -f "$_fj_env" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$_fj_env"
    set +a
fi
unset _fj_env
'

ZNUKE_SNIPPET='
# znuke: clear all zellij sessions — live, exited, and zombie.
znuke() {
    command -v zellij >/dev/null || { echo "zellij not in PATH"; return 1; }
    yes y 2>/dev/null | zellij kill-all-sessions   >/dev/null 2>&1
    yes y 2>/dev/null | zellij delete-all-sessions >/dev/null 2>&1

    local _tmp_candidates=("${TMPDIR:-}" "${TMP:-}" "${TEMP:-}" /tmp /c/msys64/tmp)
    if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
        [[ -n "${LOCALAPPDATA:-}" ]] && _tmp_candidates+=("$(cygpath -u "$LOCALAPPDATA")/Temp")
    fi
    local _seen=" " _d
    for _d in "${_tmp_candidates[@]}"; do
        [[ -z "$_d" || "$_seen" == *" $_d "* ]] && continue
        _seen+="$_d "
        [[ -L "$_d/zellij" ]] && rm -f "$_d/zellij"
        rm -rf "$_d/zellij/contract_version_"*"/" 2>/dev/null
    done

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

PING_WRAPPER_SNIPPET='
# Windows ping.exe rejects GNU -c; map it to -n for bash muscle memory.
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    ping() {
        local args=()
        while (($#)); do
            case "$1" in
                -c)
                    shift
                    [[ $# -gt 0 ]] || { echo "ping: -c requires an argument" >&2; return 2; }
                    args+=(-n "$1")
                    shift
                    ;;
                *) args+=("$1"); shift ;;
            esac
        done
        command ping "${args[@]}"
    }
fi
'

GIT_AI_COMMIT_SNIPPET='
# AI-assisted git commits: auto-append Co-authored-by via prepare-commit-msg hook
export GIT_AI_COMMIT=1
'
GIT_PROMPT_SNIPPET='
# git prompt (after tool init so PROMPT_COMMAND/PS1 stay final)
_git_prompt() {
    local b dirty
    b=$(command git symbolic-ref --short HEAD 2>/dev/null) || { GIT_INFO='"'"''"'"'; return; }
    [[ -n $(command git status --porcelain 2>/dev/null) ]] && dirty='"'"' *'"'"'
    GIT_INFO=" (${b}${dirty})"
}
PROMPT_COMMAND='"'"'_git_prompt'"'"'
export PS1='"'"'\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[36m\]${GIT_INFO}\[\e[0m\]\n\$ '"'"'
'

# ── bashrc / zshrc ───────────────────────────────────────────────────────────

# Strip a single top-level `if … fi` block that starts with a matching comment header.
remove_if_fi_block() {
    local rc="$1" header_re="$2"
    [[ -f "$rc" ]] || return 0
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

sync_extra_windows_profiles() {
    if ! is_windows; then return 0; fi
    local win_home_rc="$1" f
    for f in /c/Users/*/.bashrc; do
        [[ -f "$f" ]] || continue
        [[ "$f" == "$win_home_rc" ]] && continue
        add_to_rc "$f"
    done
}

add_to_rc() {
    local rc="$1"
    [[ ! -f "$rc" ]] && touch "$rc"

    remove_znuke_function "$rc"
    if ! grep -q '^z()' "$rc" 2>/dev/null; then
        remove_aliases_block "$rc"
    elif grep -q "alias z='zellij'" "$rc" 2>/dev/null; then
        sed -i "/alias z='zellij'/d" "$rc"
    fi

    ensure_snippet "$rc" "cargo PATH"       '_cargo_bin'     "$CARGO_PATH_SNIPPET"
    ensure_snippet "$rc" "opencode PATH"    '\.opencode/bin' "$OPENCODE_SNIPPET"
    ensure_snippet "$rc" "per-user TMP"     '_user_tmp='     "$USER_TMP_SNIPPET"
    ensure_snippet "$rc" "zellij PATH"      '_zellij_bin='   "$ZELLIJ_PATH_SNIPPET"
    ensure_snippet "$rc" "zellij config"    'ZELLIJ_CONFIG_DIR' "$ZELLIJ_SNIPPET"
    ensure_snippet "$rc" "zellij wrapper"   '^z()'           "$ZELLIJ_WRAPPER_SNIPPET"
    ensure_snippet "$rc" "aliases"          'alias l='       "$ALIASES_SNIPPET"
    ensure_snippet "$rc" "fnm"              'fnm env'        "$FNM_SNIPPET"
    ensure_snippet "$rc" "fzf"              'fzf --bash'     "$FZF_SNIPPET"
    ensure_snippet "$rc" "dotnet PATH"      '/c/Program Files/dotnet' "$DOTNET_SNIPPET"
    ensure_snippet "$rc" "Azure CLI PATH"   '/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin' "$AZURE_CLI_SNIPPET"
    ensure_snippet "$rc" "Tailscale PATH"   '/c/Program Files/Tailscale' "$TAILSCALE_SNIPPET"
    ensure_snippet "$rc" "Forgejo MCP env"  '\.config/forgejo/env' "$FORGEJO_SNIPPET"
    ensure_snippet "$rc" "ping wrapper"     'ping() {'       "$PING_WRAPPER_SNIPPET"
    ensure_snippet "$rc" "git prompt"       '_git_prompt'    "$GIT_PROMPT_SNIPPET"
    ensure_snippet "$rc" "git AI commits"   'GIT_AI_COMMIT=1' "$GIT_AI_COMMIT_SNIPPET"
    ensure_snippet "$rc" "znuke"            'znuke()'        "$ZNUKE_SNIPPET"
}

setup_git() {
    local git_dir="$SCRIPT_DIR/config/git"
    mkdir -p "$HOME/.config/git/hooks"
    cp "$git_dir/hooks/prepare-commit-msg" "$HOME/.config/git/hooks/"
    chmod +x "$HOME/.config/git/hooks/prepare-commit-msg"
    cp "$git_dir/ai-attribution" "$HOME/.config/git/ai-attribution"
    link_config "$git_dir/gitconfig" "$HOME/.gitconfig" "gitconfig"
    git config --global core.hooksPath "$HOME/.config/git/hooks"
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

# ── zellij ───────────────────────────────────────────────────────────────────

ZELLIJ_MSI_URL='https://github.com/zellij-org/zellij/releases/download/v0.44.3/zellij-x86_64-pc-windows-msvc-installer.msi'

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

    if ! command -v curl &>/dev/null; then
        echo "zellij not found — need curl to download the Windows MSI"
        return
    fi

    local tmpdir msi win_msi
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' RETURN
    msi="$tmpdir/zellij-installer.msi"
    echo "Installing zellij 0.44.3 MSI..."
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

# ── zellij uninstall ──────────────────────────────────────────────────────────

uninstall_zellij_data() {
    local base
    for base in "${@:-}"; do
        [[ -z "$base" ]] && continue
        rm -rf "$base/AppData/Local/Zellij" "$base/AppData/Local/Zellij Contributors" 2>/dev/null
        rm -rf "$base/.config/zellij" 2>/dev/null
        rm -f "$base/.local/bin/z-nuke" 2>/dev/null
        rm -rf "$base/.cache/zellij" "$base/.local/share/zellij" "$base/.local/state/zellij" 2>/dev/null
        rm -f "$base/.cargo/bin/zellij" 2>/dev/null
    done
}

uninstall_zellij() {
    echo "=== Uninstalling zellij ==="
    pkill -9 zellij 2>/dev/null || true

    if is_windows && command -v powershell.exe &>/dev/null; then
        powershell.exe -NoProfile -Command \
            "Get-Package -Name 'Zellij' -ErrorAction SilentlyContinue | Uninstall-Package -Force" \
            2>/dev/null || true
        powershell.exe -NoProfile -Command \
            'foreach ($scope in "User","Machine") { $p = [Environment]::GetEnvironmentVariable("Path", $scope); if ($p -and $p -match "Zellij") { $np = ($p -split ";" | Where-Object { $_ -notmatch "Zellij" }) -join ";"; [Environment]::SetEnvironmentVariable("Path", $np, $scope) } }' \
            2>/dev/null || true
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

    rm -rf "$SCRIPT_DIR/.zellij-shared" /tmp/zellij /c/msys64/tmp/zellij 2>/dev/null
    for t in /c/Users/*/AppData/Local/Temp/zellij; do
        [[ -e "$t" || -L "$t" ]] && rm -rf "$t"
    done

    # Re-apply non-zellij shell snippets after purge.
    setup_bash "$HOME"
    if is_windows; then
        local wh; wh="$(win_home)"
        [[ "$wh" != "$HOME" ]] && setup_bash "$wh"
        sync_extra_windows_profiles "$wh/.bashrc"
    fi

    echo "Zellij removed. Restart your shell or run: source ~/.bashrc"
}

# ── main ─────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--uninstall-zellij" ]]; then
    uninstall_zellij
    exit 0
fi

is_windows && install_msys2_packages
is_windows && install_zellij

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
if is_windows; then
    link_config "$SCRIPT_DIR/config.kdl" "$(win_home)/.config/zellij/config.kdl" "zellij"
else
    link_config "$SCRIPT_DIR/config.kdl" "$HOME/.config/zellij/config.kdl" "zellij"
fi

if [[ -f "$SCRIPT_DIR/z-nuke" ]]; then
    local_bin=
    if is_windows; then local_bin="$(win_home)/.local/bin"; else local_bin="$HOME/.local/bin"; fi
    mkdir -p "$local_bin"
    cp "$SCRIPT_DIR/z-nuke" "$local_bin/z-nuke"
    chmod +x "$local_bin/z-nuke"
    echo "Installed z-nuke (aggressive Zellij zombie cleaner)"
fi

patch_nvim_plugins
install_opencode_skill
upgrade_opencode

echo "Done. Restart your shell or run: source ~/.bashrc"
