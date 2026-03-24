---
name: git-ai-commits
description: Rules for AI assistants making git commits with proper identity and verification
license: MIT
compatibility: opencode, claude-code
metadata:
  category: git
  audience: ai-assistants
---

## What I do

Ensure AI assistants make verified git commits with proper attribution.

## Critical Rules

1. **Know your identity** - Before committing, know which model you are
2. **Never change git identity** - Use human's global config
3. **Use Co-authored-by** - Add yourself as co-author, not author/committer
4. **Take responsibility** - Use your actual model name

## Correct Commit Format

```bash
git commit -S -m "Your commit message

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
```

Or for Grok:
```bash
git commit -S -m "Your commit message

Co-authored-by: opencode (grok-4-1-fast) <grok@x.ai>"
```

## Common AI Co-author Formats

| Model | Co-authored-by |
|-------|----------------|
| Claude Opus | `Claude (claude-opus-4-5) <noreply@anthropic.com>` |
| Claude Sonnet | `Claude (claude-sonnet-4) <noreply@anthropic.com>` |
| Grok | `opencode (grok-4-1-fast) <grok@x.ai>` |
| GPT-4 | `GPT (gpt-4) <noreply@openai.com>` |

## What NOT to do

```bash
# WRONG - breaks verification
git config --local user.name "Claude"
git config --local user.email "noreply@anthropic.com"
git commit -m "..."  # Unverified! Signed with human's key but AI identity

# WRONG - taking credit for another AI
Co-authored-by: Grok <grok@x.ai>  # But you're Claude!
```

## Why This Matters

1. SSH signing key belongs to the human, not the AI
2. GitHub verifies signature matches committer email
3. If committer = AI email, signature won't match = unverified
4. `Co-authored-by` gives AI credit without breaking verification

## History Cleanup

If you made a bad commit:
```bash
git reset --hard <good-commit>
# Re-apply changes manually
git push --force
```

Or amend last commit:
```bash
git commit --amend -S -m "Fixed message

Co-authored-by: YourModel (model-id) <email>"
git push --force
```

## Before Every Commit

Ask yourself:
1. Who am I? (Check your model ID)
2. Am I using human's git config? (Don't set local user.name/email)
3. Did I add correct Co-authored-by with MY identity?

## Tool Transparency

Before executing any tool, **announce it in plain text**:

```
**I am Claude (claude-opus-4-5)**

**Using MCP**: github_search_repositories to find repos...
**Using Bash**: git commit -S -m "..."
**Using Edit**: updating README.md...
```

### Tool Categories

| Category | Prefix | Examples |
|----------|--------|----------|
| GitHub MCP | `**Using MCP**:` | search repos, list issues, get PR |
| Git operations | `**Using Bash**:` | commit, push, branch, reset |
| File operations | `**Using Edit/Read/Write**:` | edit, read, write files |

### Before Any Action

Always state:
1. **Your identity** - "I am [Model] ([model-id])"
2. **Tool being used** - "Using [MCP/Bash/Edit]: ..."
3. **What it does** - Brief description

### Example Workflow

```
**I am Claude (claude-opus-4-5)**

**Using MCP**: github_list_issues to check open issues...
**Using Edit**: updating README.md with new section...
**Using Bash**: git add README.md
**Using Bash**: git commit -S -m "Update README

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
**Using Bash**: git push
```

This helps humans see exactly what the AI is doing and with which tools.
