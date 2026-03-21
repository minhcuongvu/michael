---
name: michael-environment
description: Guide for AI agents working in Michael's Windows MSYS2/UCRT64 development environment
license: MIT
compatibility: opencode, claude-code
metadata:
  category: environment
  audience: ai-assistants
---

## Environment Overview

This is a **Windows development environment** using MSYS2 with the UCRT64 toolchain. The shell is bash launched through WezTerm.

## Critical Path Information

**Your shell is MSYS2 bash, not Windows CMD/PowerShell.**

| Location | Path | Purpose |
|----------|------|---------|
| User home | `/c/Users/Michael` | Windows user profile |
| MSYS2 home | `/home/Michael` or `/c/Users/Michael` | Same location via CHERE_INVOKING |
| Dotfiles repo | `/c/Dev/michael` | This repository |
| opencode | `/c/Dev/opencode` | AI assistant binary |
| Cargo | `/c/Users/Michael/.cargo/bin` | Rust tools (zellij, fnm, cargo) |
| MSYS2 tools | `/c/msys64/ucrt64/bin` | Native Windows binaries |
| Git | `/c/msys64/ucrt64/bin/git.exe` | UCRT64 git (use this, not Git for Windows) |

## Available Tools

### Rust/Cargo (in `~/.cargo/bin`)
- `zellij` - Terminal multiplexer (v0.44.0, custom build)
- `fnm` - Fast Node Manager (v1.39.0)
- Standard: `cargo`, `rustc`, `rustfmt`, `clippy`

### MSYS2 UCRT64 (in `/c/msys64/ucrt64/bin`)
- `nvim` - Neovim (lazy.nvim-based config, managed externally and linked by init.sh)
- `rg` - ripgrep
- `jq` - JSON processor
- `fzf` - Fuzzy finder with shell key bindings
- `gcc`, `g++` - MinGW-w64 compiler
- `make` (actually `mingw32-make`)
- `git` - Git for UCRT64
- `node`, `npm` - Node.js
- `python`, `python3` - Python 3.14
- `cmake`, `ninja` - Build tools

### Aliases (defined in `.bashrc`)
- `z` → `zellij` (with tab completion)
- `l` → `ls`
- `make` → `mingw32-make`

## Path Handling Rules

**ALWAYS use Unix-style paths in bash:**
- ✅ `/c/Users/Michael/project`
- ❌ `C:\Users\Michael\project`
- ❌ `C:/Users/Michael/project` (sometimes works, avoid)

**For Windows-native tools that need Windows paths:**
```bash
winpath=$(cygpath -w "/c/Users/Michael/file.txt")
# Results in: C:\Users\Michael\file.txt
```

## Git Workflow

**Use UCRT64 git, not Git for Windows:**
```bash
which git
# Should show: /c/msys64/ucrt64/bin/git
```

**Git prompt shows:**
- Branch name
- Dirty indicator (` *`) when uncommitted changes exist

## Node.js Management

**fnm (Fast Node Manager) is installed:**
```bash
fnm list          # List installed versions
fnm use 20        # Switch to Node 20
fnm install 22    # Install Node 22
```

**Default version:** v24 (from `.node-version` file)

## Zellij (Terminal Multiplexer)

**Key bindings:**
- `Ctrl+g` - Lock/unlock input
- `Ctrl+t` - Tab mode
- `Ctrl+p` - Pane mode
- `Ctrl+n` - Resize mode
- `Ctrl+s` - Scroll mode
- `Ctrl+b` - Tmux compatibility mode

**In pane mode (`Ctrl+p`):**
- `n` - New pane
- `r` - New pane right
- `d` - New pane down
- `h/j/k/l` - Move focus
- `x` - Close pane

**Theme:** tokyo-night  
**Default layout:** compact

## Common Operations

### Running Node scripts
```bash
# fnm automatically switches based on .node-version
node script.js
npm run dev
```

### Building C/C++ projects
```bash
# Use mingw32-make (aliased as make)
make
# Or
mingw32-make

# Or with cmake
mkdir build && cd build
cmake .. -G "MinGW Makefiles"
make
```

### File operations
```bash
# Use rg (ripgrep) instead of grep
rg "pattern" --type ts

# Use fd (if installed) or find
find . -name "*.rs" -type f
```

## Environment Variables

Key vars set by WezTerm/init.sh:
- `MSYSTEM=UCRT64` - MSYS2 subsystem
- `CHERE_INVOKING=1` - Preserves current directory
- `MSYS2_PATH_TYPE=inherit` - Inherits Windows PATH

## Installing Packages

**When installing packages on Windows, ALWAYS use the UCRT64 prefix:**

```bash
# CORRECT - installs UCRT64 native binary
pacman -S mingw-w64-ucrt-x86_64-ripgrep
pacman -S mingw-w64-ucrt-x86_64-jq

# WRONG - installs MSYS2-native version (may not work)
pacman -S ripgrep
pacman -S jq
```

**Package naming:** `mingw-w64-ucrt-x86_64-<package>`

Examples installed by init.sh:
- `mingw-w64-ucrt-x86_64-ripgrep`
- `mingw-w64-ucrt-x86_64-jq`

**To search for packages:**
```bash
pacman -Ss <search-term>
```

## What NOT to do

```bash
# WRONG - using backslashes in bash
cd C:\Users\Michael

# WRONG - using Windows git in MSYS2
"C:/Program Files/Git/bin/git.exe" status

# WRONG - using cmd commands
dir
cls

# CORRECT - use Unix equivalents
ls
clear
cd /c/Users/Michael
```

## Troubleshooting

**"command not found" for cargo tools:**
- Check PATH includes `/c/Users/$USER/.cargo/bin`
- Run `source ~/.bashrc`

**Git acts weird/shows wrong paths:**
- Make sure you're using `/c/msys64/ucrt64/bin/git`
- Not `C:/Program Files/Git/bin/git.exe`

**Windows paths in scripts:**
- Use `cygpath -w` to convert Unix→Windows
- Use `cygpath -u` to convert Windows→Unix

## Neovim Configuration

Neovim is set up as a separate configuration repository. `init.sh` will:
1. Link the external nvim config to `~/AppData/Local/nvim` (Windows) or `~/.config/nvim` (Linux)
2. Apply patches to neo-tree.nvim for better Windows compatibility

**To open nvim:**
```bash
nvim
# or
nvim filename.txt
```

**If nvim config is not linked:**
- Ensure the external nvim repository exists
- Run `bash init.sh` from this repo to create the symlink

## Re-running Setup

If environment seems broken:
```bash
cd /c/Dev/michael
bash init.sh
source ~/.bashrc
```

This re-links configs (including nvim) and ensures PATH is correct.
