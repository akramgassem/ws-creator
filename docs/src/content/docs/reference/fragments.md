---
title: Fragments and modules
description: Shared cloud-config and scripts.
---

| Name | Kind | Does |
|---|---|---|
| `base` | cloud-config | base packages, journald, linger |
| `mise` | cloud-config | mise and its tools |
| `guard` | cloud-config | git hooks, `machine-*` commands |
| `podman` | cloud-config | podman as root, socket for the group, Docker compatible |
| `ssh` | cloud-config | sshd on `127.0.0.1`, key only |
| `agent` | script | `~/.claude/CLAUDE.md`, `/tidy`, session hook |

## Module contract

- Runs as root; receives `WS_CREATOR_*` variables (`WS_CREATOR_USER`...).
- `lib.sh` is prepended: `user_home`, `as_user`.
- Rerunnable: `apply` may run it again.
- Act as the user with `sudo -u "$WS_CREATOR_USER" -H`, never `-i`.
- No secrets in variables: they show in `ps`.
