---
name: michael-environment
description: Guide for AI agents working in Michael's Windows MSYS2/UCRT64 development environment
license: MIT
compatibility: opencode, claude-code
metadata:
  category: environment
  audience: ai-assistants
---

## Overview

Windows dev via **MSYS2 UCRT64 bash** in WezTerm — not CMD/PowerShell. Use Unix paths (`/c/Users/Michael/...`), never `C:\...`. For Windows-native tools: `winpath=$(cygpath -w "/c/...")` (`-u` for the reverse).

| Location | Path |
|----------|------|
| User home | `/c/Users/Michael` |
| Dotfiles | `/c/Dev/michael` |
| opencode | `/c/Dev/opencode` |
| Cargo bin | `/c/Users/Michael/.cargo/bin` — `fnm`, `cargo`, `rustc`, `rustfmt`, `clippy` |
| UCRT64 bin | `/c/msys64/ucrt64/bin` — `nvim`, `rg`, `jq`, `fzf`, `gcc`/`g++` (v15.2, CGO), `mingw32-make`, `git`, `node`/`npm`, `python3`, `cmake`, `ninja` |
| Claude Code | `~/.local/bin/claude` |
| Zellij | `%LOCALAPPDATA%/Zellij/zellij.exe` (MSI via `init.sh`, not Cargo) |

**Git:** use UCRT64 git `/c/msys64/ucrt64/bin/git` (`which git` to confirm) — **not** Git for Windows. `GIT_AI_COMMIT=1` auto-appends `Co-authored-by` via `prepare-commit-msg` hook; attribution rules in [`git-ai-commits`](../git-ai-commits/SKILL.md).

**Node:** `fnm` manages versions; default v24 (`.node-version`). `fnm use 20` / `fnm install 22`.

**Shell helpers:** `z` (no args) attaches/creates Zellij session `one`, else passes through; `znuke` gentle cleanup, `z-nuke` nuclear reset; `l`→`ls`, `make`→`mingw32-make`.

**Zellij keys:** `Ctrl+g` lock · `Ctrl+t` tab · `Ctrl+p` pane · `Ctrl+n` resize · `Ctrl+s` scroll · `Ctrl+b` tmux. Pane mode: `n`/`r`/`d` new · `h/j/k/l` focus · `x` close.

## Packages

Always UCRT64 prefix: `pacman -S mingw-w64-ucrt-x86_64-<pkg>` (not bare). Search `pacman -Ss <term>`.

## Don't

Backslash paths, `dir`/`cls`, or Git for Windows. Use `ls`, `clear`, Unix paths instead.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| cargo tools not found | PATH needs `~/.cargo/bin`; `source ~/.bashrc` |
| Git wrong paths | Use `/c/msys64/ucrt64/bin/git` |
| Path conversion | `cygpath -w` (Unix→Win), `-u` (Win→Unix) |
| Broken env | `cd /c/Dev/michael && bash init.sh && source ~/.bashrc` |
| Duplicate `z()` in `.bashrc` | Re-run `bash init.sh` (dedup) or remove extras |
| Neovim config missing | `bash init.sh` (symlinks external config → `~/AppData/Local/nvim`) |

## NordVPN + Tailscale + Forgejo

NordVPN blocks non-tunneled apps from Tailscale (`100.x.x.x`). Add **Windows `.exe` paths** to split tunnel:

- Tailscale: `C:\Program Files\Tailscale\tailscale.exe`, `tailscaled.exe`
- Forgejo MCP: `C:\dev\forgejo-mcp\forgejo-mcp-server.exe`
- Git HTTP to Forgejo: `C:\msys64\ucrt64\libexec\git-core\git-remote-http.exe` (+ optionally `...\bin\git.exe`)

**Do NOT** allowlist `git-remote-https.exe` — breaks GitHub TLS through VPN. `http://` Tailscale remotes bypass VPN; `https://` GitHub uses VPN (use `https://github.com/...`, no `www`).

Symptoms: HTTP blocked → `Bad access` / `Failed to connect ... after 0 ms`. HTTPS bypass → `Recv failure: Connection was reset` on GitHub. Debug: `curl -v --connect-timeout 5 http://100.124.195.47:3000/` · `GIT_TRACE=1 git fetch upstream`.

## Grok-specific

If you are Grok, see [`grok.md`](../../grok.md) for pwsh→bash command wrapping and process-tree specifics.
