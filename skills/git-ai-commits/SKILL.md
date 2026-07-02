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

Never change git identity (use the human's global config — the SSH signing key and email are theirs, and the committer must match the signed email to verify). Add a `Co-authored-by` trailer with your **real** model — never impersonate another AI. Sign every commit with `-S`.

```bash
git commit -S -m "Your message

Co-authored-by: Claude (claude-opus-4-5) <noreply@anthropic.com>"
```

| Model | Co-authored-by |
|-------|----------------|
| Claude Opus | `Claude (claude-opus-4-5) <noreply@anthropic.com>` |
| Claude Sonnet | `Claude (claude-sonnet-4) <noreply@anthropic.com>` |
| Grok (CLI / Composer) | `Grok (grok-composer-2.5-fast) <grok@x.ai>` |
| Grok (opencode) | `opencode (grok-4-1-fast) <grok@x.ai>` |
| GPT-4 | `GPT (gpt-4) <noreply@openai.com>` |

## Don't

- `git config --local user.name/email` — breaks verification
- `git commit` without `-S` — unsigned
- Wrong `Co-authored-by` for your identity

## Fix bad commits

```bash
git reset --hard <good-commit> && git push --force        # or
git commit --amend -S -m "msg\n\nCo-authored-by: ..." && git push --force
```

## Pre-commit checklist

Who am I (model ID)? · Using human's git config (no local user.name/email)? · Correct `Co-authored-by`? · Signed with `-S`?

## Tool transparency

Before each action announce in plain text your identity, tool category (`MCP`/`Bash`/`Edit`), and what it does:

```
**I am Claude (claude-opus-4-5)**
**Using Bash**: git commit -S -m "..."
```
