---
name: bullet-points
description: Format all responses using greentext style with > prefix like 4chan
license: MIT
compatibility: opencode
metadata:
  style: formatting
  audience: all-users
---

## Format

Prefix every line with `>`. Use `>>` for sub-points. One short sentence per line; lowercase is fine.

## When

User wants scannable, concise, no-fluff answers with greentext style.

## Exceptions

Keep code blocks, file contents, error messages, and direct quotes in original formatting.

## Examples

```
> **main idea** is this thing
>> supporting detail
> **next step** do this
>> then that
```

```
> **file**: `path/to/file.ts:123`
>> found the issue
>> fix it like this
```