# michael

Personal dotfiles and shell environment setup for Windows (MSYS2/UCRT64) and Linux.

## What's Inside

| File | Purpose |
|------|---------|
| `init.sh` | Bootstrap script — sets up shell config, symlinks, and PATH |
| `wezterm.lua` | WezTerm terminal config (font, padding, MSYS2/UCRT64 shell) |
| `config.kdl` | Zellij multiplexer config (keybindings, tokyo-night theme, compact layout) |
| `skill.md` | AI agent skill for this environment (paths, tools, conventions) |

## Neovim Setup

Neovim is configured with a separate repository. `init.sh` automatically links it to your nvim config directory and applies necessary patches for neo-tree.nvim.

## Quick Start

```bash
git clone <repo-url> ~/dev/michael   # or wherever you keep repos
cd ~/dev/michael
bash init.sh
```

Restart your shell (or `source ~/.bashrc`) and you're done.

## What `init.sh` Does

1. **PATH setup** — adds tool directories that MSYS2's minimal PATH strips:
   - Cargo (`~/.cargo/bin`)
   - Docker Desktop (Windows only)
   - Go + GOPATH/bin (Windows only)
   - opencode (Windows only)

2. **Aliases**
   - `make` → `mingw32-make` (Windows/MSYS2 only, auto-detected)
   - `z` → `zellij` (with tab completion)
   - `l` → `ls`

3. **Git prompt** — shows branch name and dirty indicator in PS1

4. **Login shell fix** — ensures `.bash_profile` sources `.bashrc` (bash `--login` skips `.bashrc` by default)

5. **Dual-home handling** — on MSYS2, writes config to both:
   - `/home/User` (MSYS2 home)
   - `/c/Users/User` (Windows home, used with `CHERE_INVOKING=1`)

6. **Symlinks** — links `wezterm.lua`, `config.kdl`, `skill.md`, and external nvim config to their expected locations
7. **AI skill** — installs `skill.md` to `~/.config/opencode/skills/michael-environment/`
8. **Neovim** — links nvim configuration and applies neo-tree patches for Windows compatibility

## WezTerm Config

- Shell: MSYS2 bash (`C:/msys64/usr/bin/bash.exe --login`)
- Environment: `MSYSTEM=UCRT64`, `CHERE_INVOKING=1`, `MSYS2_PATH_TYPE=inherit`
- `MSYS2_PATH_TYPE=inherit` preserves the full Windows system PATH inside MSYS2

## Zellij Config

- Theme: tokyo-night
- Layout: compact
- Leader-key keybinds with vim-style navigation (h/j/k/l)
- tmux compatibility mode (`Ctrl+b`)

## Installing Packages

**On Windows (MSYS2/UCRT64):**

Use `pacman` with the UCRT64 prefix for native Windows binaries:

```bash
# Install packages for UCRT64 toolchain
pacman -S mingw-w64-ucrt-x86_64-<package-name>

# Examples installed by init.sh:
pacman -S mingw-w64-ucrt-x86_64-ripgrep
pacman -S mingw-w64-ucrt-x86_64-jq
```

**DO NOT use bare package names** (like `pacman -S ripgrep`) - those install MSYS2-native versions that may not work correctly with the UCRT64 toolchain.

**On Linux:**

Use your distribution's package manager:
```bash
# Debian/Ubuntu
sudo apt install ripgrep jq

# Arch
sudo pacman -S ripgrep jq
```

## Platform Notes

**Windows (MSYS2/UCRT64):** Primary target. WezTerm launches MSYS2 bash as login shell with UCRT64 toolchain. `init.sh` handles the dual-home quirk and adds Windows tool paths.

**Linux:** Supported. `init.sh` detects the OS and skips Windows-specific PATH entries. Cargo, aliases, git prompt, and symlinks work the same way.

## AI Agent Skill

The `skill.md` file contains environment documentation for AI assistants (opencode, Claude Code, etc.). `init.sh` automatically links it to:

```
~/.config/opencode/skills/michael-environment/SKILL.md
```

This skill teaches AI agents:
- Correct path handling (Unix-style in MSYS2)
- Available tools and their locations
- Aliases (`z` → `zellij`, `make` → `mingw32-make`)
- Git workflow (use UCRT64 git)
- Zellij keybindings
- Common pitfalls to avoid

The skill follows the standard skill format used by opencode and can be loaded automatically when working in this environment.
