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

DOTNET_SNIPPET="
# machine-wide .NET CLI
if [[ -n \"\$MSYSTEM\" || \"\$OSTYPE\" == msys* ]]; then
    _dotnet_bin='$DOTNET_ROOT'
    [[ -d \"\$_dotnet_bin\" ]] && case \":\$PATH:\" in *:\"\$_dotnet_bin\":*) ;; *) export PATH=\"\$_dotnet_bin:\$PATH\" ;; esac
    unset _dotnet_bin
fi
"

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
}
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
    if ! grep -q '^z()' "$rc" 2>/dev/null; then
        remove_aliases_block "$rc"
    elif grep -q "alias z='zellij'" "$rc" 2>/dev/null; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            echo "[DRY-RUN] would remove legacy alias z='zellij' from $rc"
        else
            sed -i "/alias z='zellij'/d" "$rc"
        fi
    fi

    ensure_snippet "$rc" "cargo PATH"       '_cargo_bin'     "$CARGO_PATH_SNIPPET"
    ensure_snippet "$rc" "opencode PATH"    '\.opencode/bin' "$OPENCODE_SNIPPET"
    ensure_snippet "$rc" "per-user TMP"     '_user_tmp='     "$USER_TMP_SNIPPET"
    if [[ "${SKIP_ZELLIJ:-0}" != "1" ]]; then
        ensure_snippet "$rc" "zellij PATH"      '_zellij_bin='   "$ZELLIJ_PATH_SNIPPET"
        ensure_snippet "$rc" "zellij config"    'ZELLIJ_CONFIG_DIR' "$ZELLIJ_SNIPPET"
        ensure_snippet "$rc" "zellij wrapper"   '^z()'           "$ZELLIJ_WRAPPER_SNIPPET"
        ensure_snippet "$rc" "aliases"          'alias l='       "$ALIASES_SNIPPET"
        ensure_snippet "$rc" "znuke"            'znuke()'        "$ZNUKE_SNIPPET"
    else
        ensure_snippet "$rc" "aliases"          'alias l='       "$ALIASES_BASE_SNIPPET"
    fi
    ensure_snippet "$rc" "fnm"              'fnm env'        "$FNM_SNIPPET"
    ensure_snippet "$rc" "fzf"              'fzf --bash'     "$FZF_SNIPPET"
    ensure_snippet "$rc" "dotnet PATH"      "$DOTNET_ROOT"   "$DOTNET_SNIPPET" fixed
    ensure_snippet "$rc" "Azure CLI PATH"   "$AZURE_CLI_ROOT" "$AZURE_CLI_SNIPPET" fixed
    ensure_snippet "$rc" "Tailscale PATH"   "$TAILSCALE_ROOT" "$TAILSCALE_SNIPPET" fixed
    ensure_snippet "$rc" "Forgejo MCP env"  '\.config/forgejo/env' "$FORGEJO_SNIPPET"
    ensure_snippet "$rc" "ping wrapper"     'ping() {'       "$PING_WRAPPER_SNIPPET"
    ensure_snippet "$rc" "git prompt"       '_git_prompt'    "$GIT_PROMPT_SNIPPET"
    ensure_snippet "$rc" "git AI commits"   'GIT_AI_COMMIT=1' "$GIT_AI_COMMIT_SNIPPET"
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
