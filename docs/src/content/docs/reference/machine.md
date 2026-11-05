---
title: A machine folder
description: machine.psd1, user-data.yaml, files/.
---

```text
<WS_CREATOR_MACHINES>\my-machine\   folder name = distro = hostname
  machine.psd1      Windows side
  user-data.yaml    the machine, in cloud-config
  AGENTS.md         optional, for coding agents
  files\            optional, system files (path = destination)
```

## machine.psd1

| Key | | |
|---|---|---|
| `BaseDistribution` | required | WSL image |
| `Location` | required | disk folder |
| `CloudConfig` | required | fragments, in order |
| `Modules` | | scripts after cloud-init |
| `PodmanSubnet` | with `podman` | unique per machine |
| `Ssh` | with `ssh` | `Port` (unique), `PublicKey` |
| `AgentInstructions` | | file copied to `~/.claude/CLAUDE.md` |
| `Description` | templates | shown by `list` |
| `Template*` | written by `init` | provenance |

## user-data.yaml

Users and permissions, `/etc/wsl.conf`, packages, mise tools. ws-creator checks that it
agrees with `machine.psd1`:

- `hostname=` is the folder name; `default=` is one of `users`;
- `Port`, `AllowUsers` and the authorized key match `Ssh`;
- `default_subnet` matches `PodmanSubnet`.

## files/

System files only, never under `/home`. Guardrail settings live here:
`etc/ws-creator/guard.conf`, `etc/ws-creator/denylist.sha256`
([guardrails](../../explanation/guardrails/)).
