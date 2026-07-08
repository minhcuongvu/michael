#!/usr/bin/env bash
# lib/setup-shell.sh — bashrc / zshrc setup and shell snippets

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/helpers.sh"

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

GROK_PATH_SNIPPET='
# grok CLI
if [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]]; then
    _grok_bin="$(cygpath -u "$USERPROFILE")/.grok/bin"
else
    _grok_bin="$HOME/.grok/bin"
fi
[[ -d "$_grok_bin" ]] && case ":$PATH:" in *:"$_grok_bin":*) ;; *) export PATH="$_grok_bin:$PATH" ;; esac
unset _grok_bin
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
# zellij wrapper — one session ("one") per profile
z() {
    command -v zellij >/dev/null || { echo "zellij not in PATH"; return 1; }
    if (($# == 0)); then
        # Stale resurrectable cache blocks attach -c; clear when no live session
        if ! zellij list-sessions 2>/dev/null | grep -qE '"'"'^one\b'"'"'; then
            find "$HOME/.cache/zellij" -path '"'"'*/session_info/one'"'"' -type d \
                -exec rm -rf {} + 2>/dev/null
        fi
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
    _zcomp="$HOME/.cache/zellij/completion.bash"
    mkdir -p "$(dirname "$_zcomp")"
    if [[ ! -s "$_zcomp" ]]; then
        timeout 5 zellij setup --generate-completion bash >"$_zcomp" 2>/dev/null || rm -f "$_zcomp"
    fi
    if [[ -s "$_zcomp" ]]; then
        # shellcheck disable=SC1090
        source "$_zcomp"
        complete -F _zellij z 2>/dev/null
    fi
    unset _zcomp
fi
alias l='"'"'ls'"'"'
if command -v mingw32-make &>/dev/null; then alias make='"'"'mingw32-make'"'"'; fi
'

ALIASES_BASE_SNIPPET='
# aliases
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

AZURE_CLI_SNIPPET="
# Azure CLI (Windows installer)
if [[ -n \"\$MSYSTEM\" || \"\$OSTYPE\" == msys* ]]; then
    _azure_cli_bin='$AZURE_CLI_ROOT'
    [[ -d \"\$_azure_cli_bin\" ]] && case \":\$PATH:\" in *:\"\$_azure_cli_bin\":*) ;; *) export PATH=\"\$_azure_cli_bin:\$PATH\" ;; esac
    unset _azure_cli_bin
fi
"

TAILSCALE_SNIPPET="
# Tailscale CLI (MSYS2 minimal PATH omits C:\\Program Files\\Tailscale)
if [[ -n \"\$MSYSTEM\" || \"\$OSTYPE\" == msys* ]]; then
    _tailscale_bin='$TAILSCALE_ROOT'
    [[ -d \"\$_tailscale_bin\" ]] && case \":\$PATH:\" in *:\"\$_tailscale_bin\":*) ;; *) export PATH=\"\$_tailscale_bin:\$PATH\" ;; esac
    unset _tailscale_bin
fi
"

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

    pkill -u "$(id -un)" zellij 2>/dev/null || true

    rm -rf "$HOME/.cache/zellij"/*/session_info/* 2>/dev/null
    rm -rf "/run/user/$(id -u)/zellij" 2>/dev/null

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

    if pgrep -u "$(id -un)" -x zellij >/dev/null 2>&1; then
        echo "znuke: zellij process still running"
        return 1
    fi
    if find "$HOME/.cache/zellij" -path '*/session_info/*' -mindepth 1 2>/dev/null | grep -q .; then
        echo "znuke: session cache still present"
        return 1
    fi
    echo "znuke: all sessions cleared"
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

FRAN_SNIPPET='
# fran — launch the Franchelsie terminal chat (TUI) from anywhere.
# Prefers a Python that has textual (3.10 here; `python` may be a newer one
# without it). Set FRAN_HOME to override the repo location.
fran() {
    local home="${FRAN_HOME:-/c/dev/franchelsie}"
    if [[ ! -d "$home/tui" ]]; then
        echo "fran: Franchelsie TUI not found at $home (set FRAN_HOME)" >&2
        return 1
    fi
    local py="" cand
    for cand in python python3 "py -3.13" "py -3.12" "py -3.11" "py -3.10" py; do
        if $cand -c "import textual" >/dev/null 2>&1; then py="$cand"; break; fi
    done
    if [[ -z "$py" ]]; then
        echo "fran: no Python with textual found. Install the TUI with:" >&2
        echo "      py -3.10 -m pip install -e \"$home/tui\"" >&2
        return 1
    fi
    # $py may be two words ("py -3.10"); leave it unquoted so it splits.
    ( cd "$home/tui" && PYTHONUTF8=1 exec $py -m tui "$@" )
}
'

GIT_AI_COMMIT_SNIPPET='
# AI-assisted git commits: auto-append Co-authored-by via prepare-commit-msg hook
export GIT_AI_COMMIT=1
'

CLAUDE_ALT_SNIPPET='
# cc2 — run Claude Code as a second, fully isolated account.
# Separate CLAUDE_CONFIG_DIR = separate auth/history/settings/MCP; same cwd, so
# both accounts can work the same project folder. First run prompts a login.
cc2() {
    command -v claude >/dev/null || { echo "claude not in PATH"; return 1; }
    local _alt="$HOME/.claude-alt"
    [[ -n "$MSYSTEM" || "$OSTYPE" == msys* ]] && _alt="$(cygpath -u "$USERPROFILE")/.claude-alt"
    CLAUDE_CONFIG_DIR="$_alt" claude "$@"
}
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

# ── rc file management ───────────────────────────────────────────────────────

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
    [[ ! -f "$rc" ]] && run touch "$rc"

    remove_znuke_function "$rc"
    remove_legacy_zellij_alias "$rc"
    if ! grep -q '^z()' "$rc" 2>/dev/null; then
        remove_aliases_block "$rc"
    fi

    ensure_snippet "$rc" "cargo PATH"       '_cargo_bin'     "$CARGO_PATH_SNIPPET"
    ensure_snippet "$rc" "opencode PATH"    '\.opencode/bin' "$OPENCODE_SNIPPET"
    ensure_snippet "$rc" "grok PATH"        '_grok_bin='     "$GROK_PATH_SNIPPET"
    ensure_snippet "$rc" "per-user TMP"     '_user_tmp='     "$USER_TMP_SNIPPET"
    if [[ "${SKIP_ZELLIJ:-0}" != "1" ]]; then
        ensure_snippet "$rc" "zellij PATH"      '_zellij_bin='   "$ZELLIJ_PATH_SNIPPET"
        ensure_snippet "$rc" "zellij config"    'ZELLIJ_CONFIG_DIR' "$ZELLIJ_SNIPPET"
        ensure_snippet "$rc" "zellij wrapper"   'z() {'           "$ZELLIJ_WRAPPER_SNIPPET"
        ensure_snippet "$rc" "aliases"          'alias l='       "$ALIASES_SNIPPET"
        ensure_snippet "$rc" "znuke"            'znuke()'        "$ZNUKE_SNIPPET"
    else
        ensure_snippet "$rc" "aliases"          'alias l='       "$ALIASES_BASE_SNIPPET"
    fi
    ensure_snippet "$rc" "fnm"              'fnm env'        "$FNM_SNIPPET"
    ensure_snippet "$rc" "fzf"              'fzf --bash'     "$FZF_SNIPPET"
    ensure_snippet "$rc" "Azure CLI PATH"   "$AZURE_CLI_ROOT" "$AZURE_CLI_SNIPPET" fixed
    ensure_snippet "$rc" "Tailscale PATH"   "$TAILSCALE_ROOT" "$TAILSCALE_SNIPPET" fixed
    ensure_snippet "$rc" "Forgejo MCP env"  '\.config/forgejo/env' "$FORGEJO_SNIPPET"
    ensure_snippet "$rc" "ping wrapper"     'ping() {'       "$PING_WRAPPER_SNIPPET"
    ensure_snippet "$rc" "fran launcher"    'fran()'         "$FRAN_SNIPPET"
    ensure_snippet "$rc" "git prompt"       '_git_prompt'    "$GIT_PROMPT_SNIPPET"
    ensure_snippet "$rc" "git AI commits"   'GIT_AI_COMMIT=1' "$GIT_AI_COMMIT_SNIPPET"
    ensure_snippet "$rc" "claude alt account" 'cc2()'         "$CLAUDE_ALT_SNIPPET"
}

setup_bash() {
    local home="$1"

    add_to_rc "$home/.bashrc"
    [[ -f "$home/.zshrc" ]] && add_to_rc "$home/.zshrc"

    local bp="$home/.bash_profile"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        if [[ ! -f "$bp" ]] || ! grep -q '\.bashrc' "$bp" 2>/dev/null; then
            echo "[DRY-RUN] would add .bashrc source to $bp"
        else
            echo "[DRY-RUN] .bash_profile already sources .bashrc ($bp)"
        fi
        return
    fi

    if [[ ! -f "$bp" ]] || ! grep -q '\.bashrc' "$bp" 2>/dev/null; then
        printf '\n[[ -f ~/.bashrc ]] && source ~/.bashrc\n' >> "$bp"
        echo "Added .bashrc source to $bp"
    else
        echo ".bash_profile already sources .bashrc"
    fi
}
