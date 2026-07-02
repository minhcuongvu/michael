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

`app1` is a monorepo; components (`frontend1`, `backend1`, …) have separate Forgejo repos as subtrees. After **any** commit or merge to a component's default branch, sync locally or the monorepo is stale:

```bash
app sync pull <component>    # e.g. app sync pull backend1
app sync status             # verify
```

## Setup

- **Forgejo:** `FORGEJO_URL` in `app.yaml`; auth via `FORGEJO_TOKEN` (`write:repository`)
- **MCP:** `C:/dev/forgejo-mcp/forgejo-mcp-server.exe`; config in `.grok/config.toml`
- **Credentials:** copy `.grok/forgejo.env.example` → `~/.config/forgejo/env` + `bash init.sh`, or set `FORGEJO_TOKEN`
- **NordVPN:** split-tunnel `forgejo-mcp-server.exe` for Tailscale
- **Verify:** restart Grok, enable `forgejo` via `/mcps`, `grok mcp doctor forgejo` (expect 18 tools)

## AI Attribution

Include a `Co-authored-by` trailer with your **real** model in every commit message and PR body — never impersonate another AI. Full model→trailer table in [`git-ai-commits`](../git-ai-commits/SKILL.md). Never set local git `user.name`/`user.email` — API commits as the token owner.

## MCP Tools

**Read:** `list_repos`, `get_repo`, `get_file` (save SHA!), `list_branches`, `get_branch`, `list_commits`, `get_commit`, `list_issues`, `get_issue`, `list_pull_requests`, `get_pull_request`, `get_pull_request_diff`

**Write:** `create_branch`, `create_or_update_file`, `delete_file`, `create_issue`, `create_pull_request`, `merge_pull_request`

## PR Workflow

1. **Read state** — `get_repo`, `list_branches`, `get_file` (save SHAs)
2. **Branch** — `create_branch`, prefix `feat/`|`fix/`|`docs/`|`refactor/`|`chore/`
3. **Commit** — `create_or_update_file` per file; include `sha` for updates + `Co-authored-by`
4. **PR** — `create_pull_request` with `Co-authored-by` in body
5. **Review** — `get_pull_request_diff`
6. **Merge** — `merge_pull_request` `merge_style: "squash"` — **ask human first**
7. **Sync** — `app sync pull <component>`

**Direct commit (no PR):** target branch via `create_or_update_file` — skips review, prefer PRs, still sync after. **Delete:** `delete_file` needs `sha` from `get_file`.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| No `sha` on update | `get_file` first |
| 409 SHA conflict | Re-read file, retry |
| Missing `branch` arg | Commits to default branch |
| Forgot sync | `app sync pull <component>` |

`get_file → create_branch → create_or_update_file → create_pull_request → merge_pull_request → app sync pull`
