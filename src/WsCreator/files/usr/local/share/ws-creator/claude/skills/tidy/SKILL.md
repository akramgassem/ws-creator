---
name: tidy
description: Picks up the crumbs that sessions left on this machine (branches whose PR is merged, orphan worktrees, forgotten dev servers, throwaway scratch folders, containers without a project), without touching another session's work. Run it at the end of a task, before saying it is done, or when machine-state reports "Crumbs".
---

# Tidy the machine

Several sessions work on this machine, often in the same repos. Pick up what this session
left behind, and what nobody claims anymore. Do not touch the rest: report it.

## 1. Detect

```bash
for g in $(find ~/src -maxdepth 5 -name .git -prune); do git -C "${g%/.git}" fetch --prune --quiet origin 2>/dev/null; done
machine-crumbs
```

`fetch --prune` only updates remote refs: never `pull`, `checkout` or `switch`, another
session may be working in the checkout. `machine-crumbs` queries GitHub (one to two minutes)
and deletes nothing. Each "~" line says who it belongs to: "this session",
"session <id> active", "session <id> ended", or nothing.

**A "session <id> active" line belongs to another session: do nothing with it, mention it
in the report.**

## 2. Clean up, by kind of crumb

- **Branch "PR #n merged"**: `machine-prune-branch <repo> <branch>` (repo: absolute path,
  `~/` + the path on the line). It checks again with `gh` that the PR is `MERGED`, that none
  is open and that every commit, local and on origin, is in the PR. Only then does it delete
  the local and the remote branch. No other command deletes a branch: neither
  `git branch -D` nor `git push --delete`. If it answers "kept: ...", the reason goes in the
  report.
- **Branch "remote deleted" without a merged PR**: do not delete it. Mention it with the
  commits `machine-leftovers` finds for it.
- **Branch "checked out in ..."**: do not delete it (git would refuse). Its worktree goes first.
- **Worktree "is gone"**: `git -C <repo> worktree prune`.
- **Worktree of an ended session**: `git -C <repo> worktree remove <path>`, without `--force`.
  If it has uncommitted changes, do nothing: report them to the user.
- **Server** "current folder deleted", "in the scratchpad of an ended session" or
  "started by this session": `kill <PID>`, then check the port is free (`ss -ltn`).
  A server tied to an active session, or of doubtful origin, is listed: do not stop it.
- **Throwaway scratch folder**: ask the user before deleting it, with the README line. If it
  contains a repo or a worktree, run `machine-leftovers` first: a "!" line for this folder
  means it is kept. A worktree is removed with `git worktree remove`, not `rm`.
- **Container without a project**: ask the user before `docker rm` (or `docker compose down`).

## 3. Guardrails

- Never touch a repo's uncommitted work, never switch branches in a checkout.
- Never `--no-verify`, never `--force`: a refusal from a hook or from git is reported, not worked around.
- When in doubt about where a crumb comes from, list it without touching it.

## 4. Finish

```bash
machine-crumbs --local
machine-leftovers
```

Short report, in three parts: what was deleted; what remains, with the reason (another
active session, unpushed work, refusal from `machine-prune-branch`, waiting for an answer);
and the "!" lines from `machine-leftovers`, the only ones that would make purge refuse.
