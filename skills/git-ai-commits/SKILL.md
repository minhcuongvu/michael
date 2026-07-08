---
name: git-ai-commits
description: >
  Rules for AI assistants making git commits with proper identity and verification.
  Read this file before any commit. Use when asked to "commit", "commit changes",
  "git commit", "push", or similar.
metadata:
  short-description: "Verified git commits with AI attribution"
---

# Git AI Commits

## Before committing

1. `git status` and `git diff` — know what you're committing
2. `git log --oneline -5` — match repo message style
3. Know your model ID for `Co-authored-by`

## Rules

- Never change git identity — use the human's global `user.name` / `user.email`
- Sign every commit: `git commit -S`
- Add `Co-authored-by` with your **real** model — never impersonate another AI
- Do not rely on unsigned commits (`git commit` without `-S`)

## Commit format

```bash
git add <files>
git commit -S -m "$(cat <<'EOF'
Subject line

Optional body paragraphs.

Co-authored-by: Grok (grok-composer-2.5-fast) <grok@x.ai>
EOF
)"
```

PowerShell (Cursor default shell):

```powershell
Set-Location C:\dev\repo
git add <files>
git commit -S -m "Subject line`n`nOptional body.`n`nCo-authored-by: Grok (grok-composer-2.5-fast) <grok@x.ai>"
```

## Model table

| Model | Co-authored-by |
|-------|----------------|
| Grok Composer (Cursor) | `Grok (grok-composer-2.5-fast) <grok@x.ai>` |
| Grok (opencode) | `opencode (grok-4-1-fast) <grok@x.ai>` |
| Claude Opus | `Claude (claude-opus-4-5) <noreply@anthropic.com>` |
| Claude Sonnet | `Claude (claude-sonnet-4) <noreply@anthropic.com>` |
| GPT-4 | `GPT (gpt-4) <noreply@openai.com>` |

## Auto-attribution hook (MSYS2)

When `GIT_AI_COMMIT=1` and `git config --global ai.coauthor` are set, the `prepare-commit-msg` hook appends `Co-authored-by` automatically. Still use `-S`. In Cursor, include the trailer in `-m` explicitly — do not assume the hook ran.

## Don't

- `git config --local user.name` / `user.email`
- Wrong `Co-authored-by` for your identity
- `git commit` without `-S`

## Fix bad commits

```bash
git commit --amend -S -m "..."   # last commit
git reset --hard <good> && git push --force   # history rewrite
```

## Checklist

Who am I? · Human git config untouched? · Signed (`-S`)? · Correct `Co-authored-by`?