---
title: Getting started
description: Install ws-creator, create a machine from a template, and connect to it.
---

This tutorial creates a work machine from the `dev` template and opens it in VS Code. It
takes about ten minutes, most of it cloud-init installing packages and tools.

## Requirements

- Windows 11 with WSL 2, in mirrored networking mode (`networkingMode=mirrored` in `~\.wslconfig`)
- PowerShell 7.4 or later
- An SSH key: `~\.ssh\id_ed25519.pub` (create it with `ssh-keygen -t ed25519` if needed)

## 1. Install

```powershell
Install-PSResource WsCreator        # or: Install-Module WsCreator
ws-creator doctor                   # checks WSL, networking, SSH config and key permissions
```

`ws-creator` is an alias of `Invoke-WsCreator`. Update later with `Update-PSResource WsCreator`.

## 2. Pick a template

```powershell
ws-creator list
```

The module ships two templates:

| Template | For |
|---|---|
| `dev` | a work machine: sudo, podman, gh, node, python, git guardrails |
| `agent-sandbox` | a coding agent: no sudo, no podman group, no Windows disk or programs |

## 3. Create the machine folder

```powershell
ws-creator init dev my-machine            # dry run: shows the values init would use
ws-creator init dev my-machine -Apply
```

`init` copies the template into `%APPDATA%\ws-creator\machines\my-machine\` with your user
name, your public key, the first free SSH port from 2222 and a free podman subnet. The
folder is now yours: change packages, tools or permissions in `user-data.yaml` as you like.
See [A machine folder](../reference/machine/) for what each file holds.

## 4. Create the distro

```powershell
ws-creator new my-machine                 # dry run: the steps
ws-creator new my-machine -Apply
```

ws-creator installs Ubuntu, seeds cloud-init with the fragments and your `user-data.yaml`,
waits for the result, runs the modules, and writes the SSH alias `my-machine` on Windows.

## 5. Connect

```powershell
ssh my-machine
ws-creator code my-machine                # VS Code Remote-SSH on ~/src
```

The distro starts on connection. On the machine, sign in to GitHub and apply your
dotfiles (git identity and personal settings):

```bash
gh auth login
chezmoi init --apply <your-account>
```

`machine-state` reminds you of these two commands until they have been run.

## Next

- [Day-to-day use](../guides/day-to-day/): reapply, stop, purge, rebuild.
- [Your own templates](../guides/templates/): turn your machine into a template.
