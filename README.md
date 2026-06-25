# michael

Personal dotfiles and shell environment setup for Windows (MSYS2/UCRT64) and Linux.

## Prerequisites

- **Windows:** [MSYS2](https://www.msys2.org/) (UCRT64), [WezTerm](https://wezfurlong.org/wezterm/)
- **Tools:** Rust/cargo (`zellij`, `fnm`), opencode, external [cloud-nvim](https://github.com/) repo at `/c/dev/cloud-nvim` (Windows) or `~/cloud-nvim` (Linux)
- **Optional:** Grok CLI, Forgejo MCP server (`C:/dev/forgejo-mcp/forgejo-mcp-server.exe`), Tailscale

## Quick Start

```bash
git clone http://100.124.195.47:3000/michael/michael.git /c/Dev/michael
cd /c/Dev/michael
bash init.sh
source ~/.bashrc
```

Restart your shell or open a new WezTerm tab.

## What's Inside

| Path | Purpose |
|------|---------|
| `init.sh` | Bootstrap — shell config, symlinks, MSYS2 packages, nvim patches |
| `wezterm.lua` | WezTerm config (font, padding, MSYS2/UCRT64 shell) |
| `config.kdl` | Zellij multiplexer (tokyo-night theme, compact layout) |
| `z-nuke` | Aggressive Zellij zombie session cleaner (installed to `~/.local/bin`) |
| `skills/` | AI agent skills (see below) |
| `copy_to_opencode_windows.sh` | Sync skills to `~/.config/opencode/skills/` |
| `.grok/` | Grok MCP config templates (Forgejo integration) |
| `patches/` | Reference patches for nvim plugins |
| `.node-version` | Default Node version for fnm (v24) |

## What `init.sh` Does

1. **MSYS2 packages** (Windows) — installs `ripgrep`, `jq`, `fzf`, `git-subtree` via UCRT64 pacman if missing
2. **PATH setup** — adds tool dirs MSYS2's minimal PATH omits:
   - Cargo (`~/.cargo/bin`)
   - opencode (`~/.opencode/bin`)
   - .NET CLI, Azure CLI, Tailscale (Windows only)
3. **Shell tools** — fnm (Node), fzf (fuzzy finder + key bindings)
4. **Aliases** — `z` → `zellij`, `l` → `ls`, `make` → `mingw32-make` (Windows)
5. **Git** — branch/dirty prompt; unaliases Git-for-Windows `git.exe` so MSYS2 git is used
6. **Forgejo env** — sources `~/.config/forgejo/env` if present (for MCP token)
7. **ping wrapper** — maps `ping -c` to `ping -n` on Windows
8. **znuke** — shell function for gentle Zellij session cleanup
9. **Login shell fix** — ensures `.bash_profile` sources `.bashrc`
10. **Dual-home handling** — writes config to both MSYS2 home and Windows home (`CHERE_INVOKING=1`)
11. **Symlinks** — `wezterm.lua`, `config.kdl`, external nvim config
12. **z-nuke** — copies aggressive Zellij cleaner to `~/.local/bin`
13. **Neovim** — links cloud-nvim config; patches neo-tree.nvim on Windows
14. **opencode** — attempts `skill.md` symlink (legacy); runs `opencode upgrade`

## WezTerm Config

- Shell: MSYS2 bash (`C:/msys64/usr/bin/bash.exe --login`)
- Environment: `MSYSTEM=UCRT64`, `CHERE_INVOKING=1`, `MSYS2_PATH_TYPE=inherit`
- `MSYS2_PATH_TYPE=inherit` preserves the full Windows system PATH inside MSYS2

## Zellij Config

- Theme: tokyo-night · Layout: compact
- Leader-key keybinds with vim-style navigation (h/j/k/l)
- tmux compatibility mode (`Ctrl+b`)

### Session Cleanup

| Tool | Type | When to use |
|------|------|-------------|
| `znuke` | Shell function | First choice — kills sessions + cleans sockets |
| `z-nuke` | `~/.local/bin` command | Nuclear option when `znuke` isn't enough (`-f` to skip prompt) |

## AI Agent Skills

Skills live in `skills/` and follow the standard `SKILL.md` format:

| Skill | Description |
|-------|-------------|
| `michael-environment` | Paths, tools, MSYS2 conventions, NordVPN/Tailscale notes |
| `forgejo-workflow` | Commits, PRs, and monorepo sync via forgejo-mcp |
| `git-ai-commits` | Git commit attribution and signing rules |
| `bullet-points` | Greentext response formatting |

### Installing Skills

**opencode** — copy all skills:

```bash
bash copy_to_opencode_windows.sh
```

**Grok / Claude Code** — skills are loaded from their respective config directories. For Grok project-scoped skills, place or symlink into `~/.grok/skills/` or the project's skill path.

> **Note:** `init.sh` still symlinks a legacy `skill.md` if present. Use `copy_to_opencode_windows.sh` for the current `skills/` directory.

## Grok MCP (Forgejo)

Templates in `.grok/` (secrets are gitignored):

```bash
# Grok MCP config
cp .grok/config.toml.example .grok/config.toml
# Edit FORGEJO_TOKEN in config.toml

# Shell env (sourced by init.sh)
mkdir -p ~/.config/forgejo
cp .grok/forgejo.env.example ~/.config/forgejo/env
# Edit FORGEJO_TOKEN in env file
```

Create a Forgejo API token (Settings → Applications) with `write:repository` scope.

If using NordVPN, add `forgejo-mcp-server.exe` and Tailscale binaries to split tunnel (see `skills/michael-environment/SKILL.md`).

Verify: restart Grok, enable `forgejo` via `/mcps`, run `grok mcp doctor forgejo`.

## Neovim Setup

Neovim config lives in a separate **cloud-nvim** repository. `init.sh` symlinks it:

- Windows: `~/AppData/Local/nvim` → `/c/dev/cloud-nvim`
- Linux: `~/.config/nvim` → `~/cloud-nvim`

On Windows, `init.sh` also patches neo-tree.nvim's `ls-files.lua` for graceful error handling.

## Installing Packages

**Windows (MSYS2/UCRT64)** — always use the UCRT64 prefix:

```bash
pacman -S mingw-w64-ucrt-x86_64-<package-name>

# Examples (also installed by init.sh):
pacman -S mingw-w64-ucrt-x86_64-ripgrep
pacman -S mingw-w64-ucrt-x86_64-jq
pacman -S mingw-w64-ucrt-x86_64-fzf
```

Do **not** use bare names (`pacman -S ripgrep`) — those install MSYS2-native builds that may not work with UCRT64.

**Linux** — use your distro package manager (`apt`, `pacman`, etc.).

## Platform Notes

**Windows (MSYS2/UCRT64):** Primary target. WezTerm launches MSYS2 bash as a login shell with the UCRT64 toolchain. `init.sh` handles the dual-home quirk and adds Windows tool paths.

**Linux:** Supported. `init.sh` skips Windows-specific PATH entries. Cargo, aliases, git prompt, and symlinks work the same way.

## Re-running Setup

```bash
cd /c/Dev/michael
bash init.sh
source ~/.bashrc
```

Preview changes without modifying anything:

```bash
bash init.sh --dry-run
```