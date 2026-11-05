---
title: Getting started
tableOfContents: false
description: Install, create a machine, connect.
---

Requires Windows 11, WSL 2 with `networkingMode=mirrored`, PowerShell 7.4+ and
`~\.ssh\id_ed25519.pub`.

```powershell
Install-PSResource WsCreator
ws-creator doctor                        # checks the workstation
ws-creator list                          # templates: dev, agent-sandbox
ws-creator init dev my-machine -Apply    # your user, key, a free port and subnet
ws-creator new my-machine -Apply         # the distro, provisioned by cloud-init
ssh my-machine                           # or: ws-creator code my-machine
```

Without `-Apply`, every command is a dry run.

| Template | For |
|---|---|
| `dev` | work: sudo, podman, gh, node, python |
| `agent-sandbox` | an agent: no sudo, no Windows disk |

The machine folder (`%APPDATA%\ws-creator\machines\my-machine\`) is yours to edit: see
[A machine folder](../reference/machine/).

On the machine, once:

```bash
gh auth login
chezmoi init --apply <account>           # your dotfiles: git identity, settings
```
