# Grok in Michael's Environment

## Who I Am
I am Grok, an AI built by xAI. I function as an interactive CLI/TUI agent specialized in software engineering tasks such as code exploration, editing, debugging, building, testing, and refactoring.

The agent binary runs from within this environment:
`C:\msys64\home\CuongVu\.grok\bin\grok.exe`

I am typically started from a WezTerm session that launches `C:/msys64/usr/bin/bash.exe --login`.

## The Actual Shell Situation
- Your interactive shell is **msys64 bash** (UCRT64) with environment from `init.sh`.
- **However**, the `run_terminal_command` tool I use internally defaults to **system pwsh** (PowerShell 7 at `C:\Program Files\PowerShell\7\pwsh.exe`).
- This means direct commands run under pwsh, not your real bash environment. This causes:
  - `ls` to produce PowerShell `Get-ChildItem` output instead of Unix `ls`
  - `/c/` paths to fail with Set-Location errors
  - Pipes, redirections, and complex quoting to break (frequent Get-Content errors)

## Required Practice for Terminal Commands
To execute in **your actual msys64 environment**, every `run_terminal_command` must be wrapped:

```powershell
& 'C:/msys64/usr/bin/bash.exe' --login -c 'your command here'
```

### Good Examples
- Simple:
  ```powershell
  & 'C:/msys64/usr/bin/bash.exe' --login -c 'ls -la'
  ```

- Multi-step with cd:
  ```powershell
  & 'C:/msys64/usr/bin/bash.exe' --login -c 'cd /c/dev/repo/ciecore; grep -r MyActivityNetworkHealthReferral --include="*.cs" . | head -5'
  ```

- For complex scripts, prefer writing a temp file:
  ```powershell
  & 'C:/msys64/usr/bin/bash.exe' --login -c '
  cat > /tmp/grok_task.sh << "EOT"
  #!/usr/bin/env bash
  set -e
  cd /c/dev/repo/...
  # commands here
  EOT
  bash /tmp/grok_task.sh
  rm -f /tmp/grok_task.sh
  '
  ```

I will use the wrapper automatically for all future terminal work in this environment.

## General Environment Info

For paths, tools, aliases, packages, and troubleshooting, see [`skills/michael-environment/SKILL.md`](skills/michael-environment/SKILL.md).

## Recommended Workflow

- **File reading / searching / editing**: Prefer the agent's built-in tools (`read_file`, `grep` (with `path=` parameter), `list_dir`, `search_replace`). These bypass the shell and are reliable.
- **Execution** (builds, tests, external repo exploration, git in msys style): Use the bash wrapper above.
- **External repos** (ciecore, cieportable): Use full `/c/dev/repo/...` paths inside the wrapper. The agent's `grep` tool can also target these paths directly when possible.

## Other Notes
- The process tree is typically: WezTerm → bash --login (msys) → grok.exe → pwsh.exe (for raw terminal tool calls). The wrapper compensates for the last hop.
- Config for the agent lives under the `.grok` directory in the msys home.
- This document lives at `/c/dev/michael/grok.md`. It is the Grok-specific guide, complementing the general `skills/michael-environment/SKILL.md`.

Follow these rules and I will behave consistently with your actual development environment instead of fighting the default pwsh backend.
