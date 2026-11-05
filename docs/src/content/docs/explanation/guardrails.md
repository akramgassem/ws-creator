---
title: Guardrails
description: Machine-wide git hooks and machine-* commands that hold for humans and coding agents alike.
sidebar:
  order: 2
---

The guardrails of the `guard` fragment live in git and in commands, not in an agent: they
hold for a human, Claude, Codex or VS Code. An agent only gets a thin adapter (the agent
module's `SessionStart` hook runs `machine-state`).

## Commands

- **`machine-state`**: containers, `gh`, branch and local state of each repo in `~/src` and
  `~/scratch`, and the number of crumbs. Readable by a human as well as an agent.
- **`machine-leftovers`**: what a purge would lose. `!` lines (changes, stash, commits on no
  remote branch) make `purge` refuse; `·` lines list `~/scratch` content outside git.
- **`machine-crumbs`**: what sessions left behind that clutters without being lost: `[gone]`
  branches, worktrees that are gone or belong to an ended session, listening servers whose
  folder was deleted, throwaway `~/scratch/<topic>` folders untouched for
  `CRUMBS_SCRATCH_DAYS` days, containers whose compose project is gone. Without `--local`, it
  also finds branches whose PR is merged (`gh`).
- **`machine-prune-branch <repo> <branch>`**: deletes a branch, local and on origin, only if
  its PR is merged, none is open, and all its commits are in the PR (squash merges
  included). The agent module allows it without confirmation: the check lives in the
  command, not in the agent.
- **`/tidy` skill**: runs `machine-crumbs`, cleans what belongs to the session or to nobody,
  asks before a scratch folder or a container, leaves alone what belongs to another active
  session, and ends with `machine-leftovers`.

## Git hooks

The system `core.hooksPath` points to `/etc/ws-creator/hooks`, where each hook is a link to
`dispatch`: it runs the ws-creator check, then the repo's own `.git/hooks/<name>`.

| Hook | Refuses |
|---|---|
| `pre-commit` | secrets (`gitleaks`) and forbidden names in staged lines and file names |
| `commit-msg` | AI attribution (if `NO_AI_ATTRIBUTION=true`) and forbidden names |
| `pre-push` | a push to a branch whose GitHub PR is already merged |

A repo-level `core.hooksPath` (husky) replaces the machine's hooks. lefthook must install
into `.git/hooks`:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath \
GIT_CONFIG_VALUE_0="$(git rev-parse --path-format=absolute --git-common-dir)/hooks" lefthook install
```

with `no_auto_install: true` in `lefthook.yml`. The pre-commit framework refuses to install
when `core.hooksPath` is set.

## Settings

- `files/etc/ws-creator/guard.conf` in the machine folder: `NO_AI_ATTRIBUTION`,
  `DENYLIST_EXCLUDE` (`owner/repo` patterns), `CRUMBS_SCRATCH_DAYS`.
- `files/etc/ws-creator/denylist.sha256`: forbidden names as sha256 hashes of lowercase words
  or word pairs, one per line. Hash of a word in PowerShell:

```powershell
-join ([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('word')) | % { $_.ToString('x2') })
```

Forbidden names do not apply to repos whose `origin` matches `DENYLIST_EXCLUDE`.
