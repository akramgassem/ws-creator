---
title: ws-creator
description: Workspace creator for developers on Windows, with WSL.
template: splash
hero:
  title: ws-creator
  tagline: Workspace creator for developers on Windows. A folder describes your WSL workspace; ws-creator builds it, updates it, deletes it.
  actions:
    - text: Get started
      link: ./getting-started/
      icon: right-arrow
---

```powershell
Install-PSResource WsCreator
ws-creator init dev my-machine -Apply
ws-creator new my-machine -Apply
ssh my-machine
```

## Why ws-creator

- **A quiet sandbox per project.** Each workspace is its own Linux machine: no tool, version
  or setting leaks from one project to another, or onto Windows.
- **Many toolchains, no clutter.** Node, Python, Rust, containers: each workspace has only
  what its work needs.
- **A fresh machine, on demand.** Test a setup, an onboarding guide or a release on a
  machine that has never seen your laptop.
- **Agents on a leash.** Run coding agents in a workspace without sudo or Windows disk;
  git guardrails stop secrets and pushes to merged branches.
- **Throw away, start over.** Purge and recreate in one command; purge refuses while work
  is unpushed.
- **One git identity per workspace.** Personal and work accounts, keys and tokens stay in
  their own workspace: nothing to switch.
- **Plain files.** A workspace is a folder of standard cloud-config, versioned and shared
  as a template.
