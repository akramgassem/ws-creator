---
title: Guardrails
description: Git hooks and machine-* commands, for humans and agents.
sidebar:
  order: 2
---

They live in git and commands, not in an agent.

| Command | Does |
|---|---|
| `machine-state` | repos, containers, `gh`, crumbs: run at session start |
| `machine-leftovers` | what a purge would lose; `!` lines block it |
| `machine-crumbs` | clutter left by sessions: merged branches, stale worktrees, servers |
| `machine-prune-branch` | deletes a branch only if its PR is merged |
| `/tidy` | cleans the session's crumbs, then checks leftovers |

| Hook | Refuses |
|---|---|
| `pre-commit` | secrets (gitleaks), forbidden names |
| `commit-msg` | AI attribution (optional), forbidden names |
| `pre-push` | a push to a merged PR's branch |

Hooks run through `core.hooksPath`, then the repo's own `.git/hooks`. A repo-level
`core.hooksPath` (husky) replaces them.

Settings, in the machine's `files/etc/ws-creator/`:

- `guard.conf`: `NO_AI_ATTRIBUTION`, `DENYLIST_EXCLUDE`, `CRUMBS_SCRATCH_DAYS`
- `denylist.sha256`: sha256 of forbidden lowercase words, one per line
