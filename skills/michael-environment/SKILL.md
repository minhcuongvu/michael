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

Windows dev environment: **MSYS2 UCRT64 bash** via WezTerm — not CMD/PowerShell.

| Location | Path |
|----------|------|
| User home | `/c/Users/Michael` |
| Dotfiles | `/c/Dev/michael` |
| opencode | `/c/Dev/opencode` |
| Cargo | `/c/Users/Michael/.cargo/bin` |
| MSYS2 tools | `/c/msys64/ucrt64/bin` |
| Git | `/c/msys64/ucrt64/bin/git.exe` (use this, not Git for Windows) |

## Tools

**Cargo (`~/.cargo/bin`):** `zellij`, `fnm`, `cargo`, `rustc`, `rustfmt`, `clippy`

**Claude Code (`~/.local/bin`):** `claude`

**UCRT64 (`/c/msys64/ucrt64/bin`):** `nvim`, `rg`, `jq`, `fzf`, `gcc`/`g++` (v15.2, CGO-enabled), `mingw32-make`, `git`, `node`/`npm`, `python3`, `cmake`, `ninja`

**Aliases:** `z`→`zellij`, `l`→`ls`, `make`→`mingw32-make`

## Path Rules

- Use Unix paths: `/c/Users/Michael/project` — never `C:\...` or `C:/...`
- Windows-native tools: `winpath=$(cygpath -w "/c/Users/Michael/file.txt")`

## Git

Use UCRT64 git (`which git` → `/c/msys64/ucrt64/bin/git`). Prompt shows branch + ` *` when dirty.

## Node

`fnm` manages versions. Default: v24 (`.node-version`). `fnm list` / `fnm use 20` / `fnm install 22`

## Zellij

`Ctrl+g` lock · `Ctrl+t` tab · `Ctrl+p` pane · `Ctrl+n` resize · `Ctrl+s` scroll · `Ctrl+b` tmux mode

Pane mode: `n`/`r`/`d` new pane · `h/j/k/l` focus · `x` close. Theme: tokyo-night, layout: compact.

## Common Commands

```bash
node script.js                    # fnm auto-switches from .node-version
make                              # mingw32-make
CGO_ENABLED=1 go build ./...      # backend1 needs CGO
rg "pattern" --type ts            # prefer rg over grep
```

## Packages

Always install UCRT64 prefix: `pacman -S mingw-w64-ucrt-x86_64-<pkg>` — not bare `pacman -S <pkg>`.

Search: `pacman -Ss <term>`

## Don't

- Backslash paths, `dir`/`cls`, or Git for Windows (`C:/Program Files/Git/bin/git.exe`)
- Use `ls`, `clear`, `cd /c/Users/Michael` instead

## Troubleshooting

| Problem | Fix |
|---------|-----|
| cargo tools not found | Check PATH has `~/.cargo/bin`; `source ~/.bashrc` |
| Git wrong paths | Use `/c/msys64/ucrt64/bin/git` |
| Path conversion | `cygpath -w` (Unix→Win), `cygpath -u` (Win→Unix) |
| Broken env | `cd /c/Dev/michael && bash init.sh && source ~/.bashrc` |

## NordVPN + Tailscale + Forgejo

NordVPN blocks non-tunneled apps from Tailscale (`100.x.x.x`). Add **Windows `.exe` paths** to split tunnel:

| Purpose | Executable |
|---------|------------|
| Tailscale | `C:\Program Files\Tailscale\tailscale.exe`, `tailscaled.exe` |
| Forgejo MCP | `C:\dev\forgejo-mcp\forgejo-mcp-server.exe` |
| Git HTTP to Forgejo | `C:\msys64\ucrt64\libexec\git-core\git-remote-http.exe` |
| Optional | `C:\msys64\ucrt64\bin\git.exe` |

**Do NOT** allowlist `git-remote-https.exe` — breaks GitHub TLS through VPN.

- `http://` Tailscale remotes → bypass VPN
- `https://` GitHub → use VPN; use `https://github.com/...` (no `www`)

Symptoms: HTTP blocked → `Bad access` / `Failed to connect ... after 0 ms`. HTTPS bypass → `Recv failure: Connection was reset` on GitHub.

```bash
curl -v --connect-timeout 5 http://100.124.195.47:3000/
GIT_TRACE=1 git fetch upstream
```

## Neovim

External config repo; `init.sh` symlinks to `~/AppData/Local/nvim`. If missing: run `bash init.sh`.