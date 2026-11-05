---
title: Fragments and modules
description: The shared cloud-config fragments, the script modules, and the contract a module follows.
---

Fragments are shared cloud-config files, without variables; modules are bash scripts for
what cloud-init cannot express. A machine lists the ones it uses in `machine.psd1`
(`CloudConfig`, `Modules`).

| Name | Kind | Does |
|---|---|---|
| `base` | cloud-config | base packages, journald, linger |
| `mise` | cloud-config | mise and the tools in its config, shims for non-interactive shells |
| `guard` | cloud-config | the machine's git hooks (`/etc/ws-creator/hooks`) and the `machine-*` commands |
| `podman` | cloud-config | podman as root, podman system group, socket open to the group, Docker compatibility |
| `ssh` | cloud-config | sshd on `127.0.0.1` only, no password; ws-creator writes the Windows SSH alias |
| `agent` | script | `~/.claude/CLAUDE.md`, the `/tidy` skill, a `SessionStart` hook running `machine-state`, an `allow` rule for `machine-prune-branch`, `~/src`, `~/scratch` |

The machine's user is uid 1000: shared fragments find it with `getent passwd 1000`, without
knowing it. Each fragment sets `merge_how: 'dict(recurse_array,no_replace)+list(append)'`,
so lists (`packages`, `write_files`, `runcmd`) add up from one fragment to the next.

## Module contract

- `modules/<m>.sh` runs as root in the distro and receives the `machine.psd1` values as
  `WS_CREATOR_*` variables, including `WS_CREATOR_USER`, checked at the top with
  `: "${VAR:?}"`.
- `modules/lib.sh` is prepended to each module (`user_home`, `as_user`): line numbers in a
  bash error include those of `lib.sh`.
- A module can be rerun: `apply` may run it again without damage. What the machine provides
  (`AgentInstructions`, authorized key) is rewritten on every run.
- To act as the user: `sudo -u "$WS_CREATOR_USER" -H`, never `-i` (`-i` goes through
  pam_systemd and causes systemd errors).
- No secrets in `WS_CREATOR_*`: the variables are visible in `ps`. Secrets are born in the
  distro (`gh auth login`, `aws sso login`) and die with it.
