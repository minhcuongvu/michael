## Summary

The refactor cleanly splits `init.sh` into `lib/{config,helpers,setup-shell,setup-tools,setup-config,uninstall}.sh`, adds `--dry-run` via a shared `run()` / `DRY_RUN` pattern, updates `copy_to_opencode_windows.sh` to use `win_home()`, and deduplicates environment docs into `skills/michael-environment/SKILL.md` with Grok-specific content left in `grok.md`. The modular structure is sound and most dry-run paths are handled consistently. The dominant risks are incomplete dry-run for zellij MSI install (network download still runs), stale opencode skill wiring (`skill.md` removed but `install_opencode_skill` still references it), and `set -euo pipefail` newly added to `init.sh` which can cause early exit on previously-tolerated failures.

## Issues

### Issue 1 -- Severity: bug
- File: lib/setup-tools.sh:54
- Description: In `--dry-run` mode, `install_zellij` still runs `curl -fsSLo` to download the MSI before checking `DRY_RUN`. Dry-run should not perform network I/O or leave misleading "Installing zellij..." output.
- Suggestion: Move the `DRY_RUN` check (and early `[DRY-RUN] would download …` / `would run: msiexec …` messages) before `curl`, or skip download entirely when `DRY_RUN=1`.
- Status: fixed

### Issue 2 -- Severity: bug
- File: lib/setup-config.sh:51
- Description: `install_opencode_skill` symlinks `$REPO_DIR/skill.md`, but that file no longer exists; skills live under `skills/michael-environment/SKILL.md`. `init.sh` therefore always skips opencode skill install while `copy_to_opencode_windows.sh` installs the real skill.
- Suggestion: Point `src` at `$REPO_DIR/skills/michael-environment/SKILL.md` (or delegate to the copy script / reuse `link_config`).
- Status: fixed

### Issue 3 -- Severity: bug
- File: init.sh:10
- Description: `set -euo pipefail` is newly added at the top of `init.sh`. The old monolithic script did not enable errexit. Commands like `cmd.exe mklink` failures, `msiexec` non-zero exits, or `grep -q` on missing files (before `touch`) will now abort the entire run mid-setup.
- Suggestion: Either remove `set -e` (keep `set -uo pipefail`), or audit every subprocess call in lib/*.sh for explicit `|| true` / error handling.
- Status: fixed

### Issue 4 -- Severity: bug
- File: lib/uninstall.sh:53
- Description: `uninstall_zellij` calls `purge_zellij_from_rc` then `setup_bash` → `add_to_rc`, which re-appends zellij PATH, wrapper, aliases, and `znuke` snippets. Comment says "Re-apply non-zellij shell snippets" but behavior re-injects zellij config. (Pre-existing on master; still unfixed in refactor.)
- Suggestion: Add a `SKIP_ZELLIJ=1` flag to `add_to_rc`, or split zellij vs non-zellij snippet injection so uninstall only restores the latter.
- Status: fixed

### Issue 5 -- Severity: bug
- File: lib/uninstall.sh:21
- Description: `uninstall_zellij` performs destructive actions with no `DRY_RUN` checks. `--uninstall-zellij` is parsed before `DRY_RUN` is exported and always mutates the system regardless of `--dry-run`.
- Suggestion: Honor `DRY_RUN` throughout uninstall, or reject the combination in `init.sh` argument parsing.
- Status: fixed

### Issue 6 -- Severity: suggestion
- File: lib/setup-config.sh:68
- Description: `install_opencode_skill` uses bare `ln -s` on Windows. `link_config` in `helpers.sh` already handles junctions, native symlinks, and copy fallback when symlink privileges are missing.
- Suggestion: Use `link_config "$src" "$dst" "opencode skill"` instead of duplicating symlink logic.
- Status: fixed

### Issue 7 -- Severity: suggestion
- File: lib/setup-config.sh:9
- Description: `setup_git` dry-run returns after a single generic message and does not preview `link_config` behavior (e.g. existing non-symlink `~/.gitconfig` would be skipped).
- Suggestion: Call `link_config` under dry-run (it already supports it) or mirror its checks in the early-return path.
- Status: fixed

### Issue 8 -- Severity: suggestion
- File: init.sh:26
- Description: Argument parsing treats any unrecognized flag as fatal; there is no validation that `--uninstall-zellij` and `--dry-run` are mutually consistent, and option order affects whether `DRY_RUN` is set before uninstall runs.
- Suggestion: Parse all flags first into variables, then dispatch once. Document or reject incompatible combinations.
- Status: fixed

### Issue 9 -- Severity: nit
- File: lib/setup-shell.sh:251
- Description: `ensure_snippet` grep patterns use `$DOTNET_ROOT`, `$AZURE_CLI_ROOT`, and `$TAILSCALE_ROOT` unescaped; paths contain `.` which grep treats as "any character" in BRE, risking false "already in rc" matches.
- Suggestion: Use `grep -F` for fixed-string matching, or escape regex metacharacters in path patterns.
- Status: fixed

### Issue 10 -- Severity: nit
- File: lib/config.sh:6
- Description: `MICHAEL_REPO`, `FORGEJO_MCP_PATH`, and `FORGEJO_URL` are defined but unused by the lib scripts (`REPO_DIR` is derived from `lib/` parent instead).
- Suggestion: Wire them in where intended, or remove/document as external-only overrides.
- Status: fixed (`MICHAEL_REPO` wired via `REPO_DIR`; Forgejo vars documented as external-only)

## Post-review fixes (bee04ab)

### Issue 11 -- Severity: bug
- File: lib/setup-shell.sh:192
- Description: `PING_WRAPPER_SNIPPET` closed its `if` block with `}` instead of `fi`, causing `syntax error near unexpected token '}'` on `source ~/.bashrc`.
- Status: fixed

### Issue 12 -- Severity: bug
- File: lib/setup-shell.sh:245
- Description: `ensure_snippet` grep pattern `'^z()'` did not match existing `z() {` blocks, so re-running `init.sh` appended duplicate `z()` functions.
- Status: fixed (pattern changed to `'z() {'`)