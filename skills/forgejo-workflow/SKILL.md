---
name: forgejo-workflow
description: Complete Forgejo development workflow for AI assistants - commits, PRs, AI attribution, and monorepo sync via forgejo-mcp
categories:
  - git
  - workflow
  - forgejo
  - mcp
---

# Forgejo Workflow Guide for AI Assistants

Complete guide for committing code, creating PRs, and managing the monorepo workflow on self-hosted Forgejo via forgejo-mcp tools.

## Architecture Context

This project (`app1`) uses a **monorepo with git subtrees**. Each component (e.g., `frontend1`, `backend1`) has its own upstream repo on Forgejo but lives as a directory inside `app1`.

**Critical Rule:** After any commit or merge to a component's default branch, you **MUST** sync the local subtree:

```bash
app sync pull <component>    # e.g., app sync pull backend1
```

Without syncing, the local monorepo is stale and out of date with the remote.

```
Forgejo repo (remote)          app1 monorepo (local)
┌──────────────────┐           ┌──────────────────────┐
│ michael/backend1 │──sync────▶│ app1/backend1/       │
│ michael/frontend1│──pull────▶│ app1/frontend1/      │
└──────────────────┘           └──────────────────────┘
     MCP writes here            Developer works here
```

## Environment

- **Forgejo instance:** Configured via `FORGEJO_URL` (see `app.yaml`)
- **Auth:** `FORGEJO_TOKEN` env var (API token with `write:repository` scope)
- **MCP server:** forgejo-mcp-server (stdio-based, via Docker or binary)

## AI Identity & Attribution

### Know Your Identity

Before committing, you must know which model you are. Never impersonate another AI.

### Co-authored-by Format

Include this in **every** commit message and PR body:

```
Co-authored-by: <Name> (<model-id>) <email>
```

| Model | Co-authored-by Trailer |
|-------|------------------------|
| Claude Opus 4.5 | `Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>` |
| Claude Opus 4.6 | `Co-authored-by: Claude Opus 4.6 <noreply@anthropic.com>` |
| Claude Sonnet 4 | `Co-authored-by: Claude (claude-sonnet-4) <noreply@anthropic.com>` |
| Grok | `Co-authored-by: opencode (grok-4-1-fast) <grok@x.ai>` |
| GPT-4 | `Co-authored-by: GPT (gpt-4) <noreply@openai.com>` |

### Rules

1. **Include Co-authored-by in every commit message**
2. **Use your real model identity** — never claim to be a different model
3. **Never set git user.name/email locally** — Forgejo API commits as the token owner
4. **Include Co-authored-by in the PR body**

## MCP Tools Reference

### Read-Only Tools

| Tool | Purpose |
|------|---------|
| `list_repos` | Search/list repositories |
| `get_repo` | Repository metadata |
| `get_file` | Read file contents + SHA (critical for updates) |
| `list_branches` / `get_branch` | Branch info |
| `list_commits` / `get_commit` | Commit history |
| `list_issues` / `get_issue` | Issue tracking |
| `list_pull_requests` / `get_pull_request` | PR info |
| `get_pull_request_diff` | View PR diff |

### Write Tools

| Tool | Purpose |
|------|---------|
| `create_branch` | Create a new branch |
| `create_or_update_file` | Commit a file (create or update) |
| `delete_file` | Commit a file deletion |
| `create_issue` | Open an issue |
| `create_pull_request` | Open a PR |
| `merge_pull_request` | Merge a PR |

## Complete PR Workflow

### 1. Understand Current State

```
Tool: get_repo        — confirm repo exists, check default branch
Tool: list_branches   — see existing branches
Tool: get_file        — read files to modify (save SHAs!)
```

### 2. Create a Feature Branch

**Branch naming conventions:**

| Prefix | Use |
|--------|-----|
| `feat/` | New features |
| `fix/` | Bug fixes |
| `docs/` | Documentation only |
| `refactor/` | Code restructuring |
| `chore/` | Maintenance, config |

Example: `feat/add-user-auth`, `fix/null-pointer-in-handler`

```
Tool: create_branch
  owner: "michael"
  repo: "backend1"
  new_branch_name: "feat/add-health-detail"
  old_branch_name: "master"
```

### 3. Make Changes (One Commit Per File)

**For each file:**

**Updating existing file (SHA required):**
```
Tool: create_or_update_file
  owner: "michael"
  repo: "backend1"
  path: "internal/handler/health.go"
  content: "<full file content>"
  message: "Add detailed health check response

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
  branch: "feat/add-health-detail"
  sha: "<sha from get_file>"
```

**Creating new file (no SHA needed):**
```
Tool: create_or_update_file
  owner: "michael"
  repo: "backend1"
  path: "internal/handler/health_test.go"
  content: "<test file content>"
  message: "Add tests for detailed health check

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
  branch: "feat/add-health-detail"
```

### 4. Create the Pull Request

```
Tool: create_pull_request
  owner: "michael"
  repo: "backend1"
  title: "Add detailed health check endpoint"
  body: "## Summary
- Extends /health to return component-level status
- Adds test coverage

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
  head: "feat/add-health-detail"
  base: "master"
```

### 5. Review the PR Diff

```
Tool: get_pull_request_diff
  owner: "michael"
  repo: "backend1"
  index: <pr_number>
```

### 6. Merge (with Human Approval)

**Always ask the human before merging.**

```
Tool: merge_pull_request
  owner: "michael"
  repo: "backend1"
  index: <pr_number>
  merge_style: "squash"
  title: "Add detailed health check endpoint (#<pr_number>)"
  message: "Extends /health to return component-level status with test coverage.

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
  delete_branch: true
```

Use `squash` to collapse multiple file commits into one clean commit on master.

### 7. Sync Changes to Local Monorepo

**Critical step — don't forget!**

**If you have shell access:**
```bash
app sync pull <component>
# Example:
app sync pull backend1
```

**If you do NOT have shell access:**

Tell the user:
> Changes have been merged to `backend1` on Forgejo. To update your local subtree, run:
> ```
> app sync pull backend1
> ```

**Verify sync status:**
```bash
app sync status    # shows whether subtrees are up-to-date
```

## Complete Round-Trip Summary

```
1. Read files on Forgejo          (get_file)
2. Create branch                  (create_branch)
3. Commit changes                 (create_or_update_file)
4. Open PR                        (create_pull_request)
5. Review diff                    (get_pull_request_diff)
6. Merge PR (with approval)       (merge_pull_request)
7. Sync to local monorepo         (app sync pull <component>)  ← DON'T FORGET
```

## Alternative: Commit Directly (No PR)

If the branch is unprotected, commit directly by targeting the branch:

```
Tool: create_or_update_file
  owner: "michael"
  repo: "backend1"
  path: "config.yaml"
  content: "key: value"
  message: "Update config.yaml

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
  branch: "master"
```

**Warning:** Direct commits to `master` skip code review. Prefer the PR workflow.

**Don't forget to sync:**
```bash
app sync pull backend1
```

## Deleting a File

```
Tool: delete_file
  owner: "michael"
  repo: "backend1"
  path: "old-file.txt"
  message: "Remove deprecated old-file.txt"
  branch: "cleanup/remove-old-files"
  sha: "abc123..."  # Required — get from get_file
```

## Common Mistakes & Fixes

| Mistake | Fix |
|---------|-----|
| Updating file without `sha` | Use `get_file` first to get current SHA |
| Branch already exists | Check with `get_branch` first, or commit to existing branch |
| SHA mismatch (409 conflict) | Someone else changed the file — re-read with `get_file` and retry |
| Wrong file committed | Create follow-up commit on same branch to fix |
| Forgetting `branch` argument | Without it, commit goes to default branch |
| Content encoding issues | Pass plain text — MCP server base64-encodes automatically |
| Not syncing after merge | Run `app sync pull <component>` to update local subtree |

## Quick Reference: Commit Single File

For simple changes, this minimal workflow:

```
1. get_file          → Read file, save SHA
2. create_or_update_file → Update with SHA + Co-authored-by
3. (Optional) create_pull_request → Open PR
4. (Optional) merge_pull_request → Merge it
5. app sync pull <component> → Sync to local
```
