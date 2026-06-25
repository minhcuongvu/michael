---
name: forgejo-workflow
description: Forgejo workflow for AI assistants — commits, PRs, attribution, monorepo sync via forgejo-mcp
categories:
  - git
  - workflow
  - forgejo
  - mcp
---

# Forgejo Workflow

Commit, PR, and sync workflow for self-hosted Forgejo via forgejo-mcp.

## Monorepo + Subtrees

`app1` is a monorepo; components (`frontend1`, `backend1`, etc.) have separate Forgejo repos as subtrees.

**After any commit or merge to a component's default branch, sync locally:**

```bash
app sync pull <component>    # e.g. app sync pull backend1
app sync status              # verify
```

Without sync, local monorepo is stale.

## Setup

- **Forgejo:** `FORGEJO_URL` in `app.yaml`; auth via `FORGEJO_TOKEN` (`write:repository`)
- **MCP:** `C:/dev/forgejo-mcp/forgejo-mcp-server.exe`; config in `.grok/config.toml`
- **Credentials:** copy `.grok/forgejo.env.example` → `~/.config/forgejo/env` + `bash init.sh`, or set `FORGEJO_TOKEN` env var
- **NordVPN:** split-tunnel `forgejo-mcp-server.exe` for Tailscale
- **Verify:** restart Grok, enable `forgejo` via `/mcps`, run `grok mcp doctor forgejo` (expect 18 tools)

## AI Attribution

Know your model. Never impersonate another AI. Include in **every** commit message and PR body:

```
Co-authored-by: <Name> (<model-id>) <email>
```

| Model | Trailer |
|-------|---------|
| Claude Opus 4.5 | `Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>` |
| Claude Opus 4.6 | `Co-authored-by: Claude Opus 4.6 <noreply@anthropic.com>` |
| Claude Sonnet 4 | `Co-authored-by: Claude (claude-sonnet-4) <noreply@anthropic.com>` |
| Grok (Grok CLI / Composer) | `Co-authored-by: Grok (grok-composer-2.5-fast) <grok@x.ai>` |
| Grok (opencode) | `Co-authored-by: opencode (grok-4-1-fast) <grok@x.ai>` |
| GPT-4 | `Co-authored-by: GPT (gpt-4) <noreply@openai.com>` |

Never set git `user.name`/`user.email` locally — API commits as token owner.

## MCP Tools

**Read:** `list_repos`, `get_repo`, `get_file` (save SHA!), `list_branches`, `get_branch`, `list_commits`, `get_commit`, `list_issues`, `get_issue`, `list_pull_requests`, `get_pull_request`, `get_pull_request_diff`

**Write:** `create_branch`, `create_or_update_file`, `delete_file`, `create_issue`, `create_pull_request`, `merge_pull_request`

## PR Workflow

1. **Read state** — `get_repo`, `list_branches`, `get_file` (save SHAs)
2. **Branch** — `create_branch` with prefix: `feat/`, `fix/`, `docs/`, `refactor/`, `chore/`
3. **Commit** — `create_or_update_file` per file; include `sha` for updates, Co-authored-by in message
4. **PR** — `create_pull_request` with Co-authored-by in body
5. **Review** — `get_pull_request_diff`
6. **Merge** — `merge_pull_request` with `merge_style: "squash"` — **ask human first**
7. **Sync** — `app sync pull <component>` (or tell user to run it)

## Direct Commit (No PR)

Target branch directly via `create_or_update_file`. Skips review — prefer PR workflow. Still sync after.

## Delete File

`delete_file` requires `sha` from `get_file`.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| No `sha` on update | `get_file` first |
| 409 SHA conflict | Re-read file, retry |
| Missing `branch` arg | Commits to default branch |
| Forgot sync | `app sync pull <component>` |

## Quick Reference

```
get_file → create_branch → create_or_update_file → create_pull_request → merge_pull_request → app sync pull
```