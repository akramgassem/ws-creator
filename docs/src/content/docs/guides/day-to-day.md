---
title: Day-to-day use
description: Reapply changes, stop, check, rebuild and purge a machine.
sidebar:
  order: 1
---

Every command that changes something is a dry run unless you add `-Apply`.

## Change a machine

Edit its folder (`%APPDATA%\ws-creator\machines\<name>\`), then reapply:

```powershell
ws-creator apply my-machine -Apply                  # every fragment and module
ws-creator apply my-machine -Only mise -Apply       # just the mise fragment
```

cloud-init **adds and never removes**: a rerun does not take back a permission and removes
no package or file. To remove something, purge and recreate (below).

## Check and stop

```powershell
ws-creator status my-machine     # distro, disk, image, cloud-init, sshd, containers, gh, unpushed work
ws-creator stop my-machine -Apply
```

Always stop with `ws-creator stop`, never with `wsl --terminate`: the distros share WSL's
network stack, and a killed container leaves its NAT rules active. If it happened,
`wsl --shutdown` stops all distros and clears them.

## Rebuild

```powershell
ws-creator purge my-machine -Apply   # asks you to type the name; refuses while work is unpushed
ws-creator new my-machine -Apply
```

`purge` lists what would be lost (uncommitted changes, stash, unpushed commits in `~/src`
and `~/scratch`) and refuses unless `-Force`. Afterwards, revoke the GitHub CLI token
(GitHub Settings > Applications), unless you created it with `gh auth login --expiring`.

## Faster rebuilds with a base image

```powershell
ws-creator image my-machine -Apply
```

The image is a fresh distro with the `base` and `mise` fragments (and `user-data.yaml`),
without key, token, sshd or service. `new` imports it when it exists. Rebuild it when
packages or tools change a lot.

## Project services

The machine starts no database or emulator. Each project declares its services in its
`compose.yaml` and starts them itself (`docker compose up -d`, or a mise task). With WSL
mirrored, a port published by podman (`ports:`) cannot be reached from the machine: use
`network_mode: host` and set the port in the service's command. Ports are shared with
Windows and every distro, so pick ports that nothing else uses.
