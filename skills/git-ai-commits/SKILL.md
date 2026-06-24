---
name: git-ai-commits
description: Rules for AI assistants making git commits with proper identity and verification
license: MIT
compatibility: opencode, claude-code
metadata:
  category: git
  audience: ai-assistants
---

## Rules

1. Know your model identity before committing
2. Never change git identity — use human's global config
3. Add `Co-authored-by` with your real model — never impersonate another AI
4. Sign commits: `git commit -S`

## Commit Format

```bash
git commit -S -m "Your message

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
```

| Model | Co-authored-by |
|-------|----------------|
| Claude Opus | `Claude (claude-opus-4-5) <noreply@anthropic.com>` |
| Claude Sonnet | `Claude (claude-sonnet-4) <noreply@anthropic.com>` |
| Grok | `opencode (grok-4-1-fast) <grok@x.ai>` |
| GPT-4 | `GPT (gpt-4) <noreply@openai.com>` |

## Why

SSH signing key belongs to the human. Committer must match signed email for verification. `Co-authored-by` credits the AI without breaking that.

## Don't

```bash
git config --local user.name "Claude"   # breaks verification
git commit -m "..."                     # unsigned
Co-authored-by: Grok <...>              # wrong if you're Claude
```

## Fix Bad Commits

```bash
git reset --hard <good-commit> && git push --force
# or
git commit --amend -S -m "Fixed message\n\nCo-authored-by: ..."
git push --force
```

## Pre-commit Checklist

1. Who am I? (model ID)
2. Using human's git config? (no local user.name/email)
3. Correct Co-authored-by for my identity?

## Tool Transparency

Before each action, announce in plain text:

```
**I am Claude (claude-opus-4-5)**
**Using Bash**: git commit -S -m "..."
**Using Edit**: updating README.md...
```

State: identity, tool category (`MCP` / `Bash` / `Edit`), and what it does.