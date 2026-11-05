---
title: ws-creator
description: WSL machines described by folders. Create, reapply and purge a machine from Windows.
template: splash
hero:
  tagline: A folder describes a WSL machine; ws-creator builds it with cloud-init, evolves it and deletes it.
  actions:
    - text: Get started
      link: ./getting-started/
      icon: right-arrow
---

```powershell
Install-PSResource WsCreator
ws-creator init dev my-machine -Apply   # a machine folder from a template, with your user and key
ws-creator new my-machine -Apply        # the WSL distro, provisioned by cloud-init
ssh my-machine                          # or: ws-creator code my-machine
```

## Why

- **Plain files, no template engine.** A machine is a `machine.psd1` and a `user-data.yaml`
  of standard cloud-config. What you read is what runs.
- **Rebuild instead of repair.** cloud-init adds and never removes: to take something back,
  purge and recreate. `purge` refuses while you have unpushed work.
- **Guardrails in git, not in an agent.** Machine-wide hooks stop secrets, forbidden names
  and pushes to merged pull requests, for humans and coding agents alike.
- **Made for real workstations.** Mirrored networking, unique ports and subnets checked
  across machines, and fragments that work under an EDR such as CrowdStrike Falcon.

## Where to go next

- [Getting started](./getting-started/): install, create and open your first machine.
- [Your own templates](./guides/templates/): personal and team catalogs.
- [Commands](./reference/commands/): every subcommand, generated from `Get-Help`.
- [Architecture](./explanation/architecture/): how a folder becomes a machine.
