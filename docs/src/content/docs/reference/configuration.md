---
title: Configuration
description: Environment variables and where ws-creator keeps machines, catalogs, images and disks.
---

| What | Default location | Variable |
|---|---|---|
| your machines (config: keep them in a private repo) | `%APPDATA%\ws-creator\machines` | `WS_CREATOR_MACHINES` |
| your template catalogs | none | `WS_CREATOR_TEMPLATES` |
| clones of git catalogs (rebuildable) | `%LOCALAPPDATA%\ws-creator\catalogs` | none |
| base images (rebuildable) | `%LOCALAPPDATA%\ws-creator\images` | `WS_CREATOR_IMAGES` |
| distro disks | `Location` in each `machine.psd1` | `WS_CREATOR_LOCATION` (default for `init`, else `C:\WSL`) |

Set the variables in your PowerShell profile, for example:

```powershell
$env:WS_CREATOR_MACHINES = 'D:\config\ws-machines'
$env:WS_CREATOR_TEMPLATES = 'D:\templates;https://github.com/acme/ws-templates'
```

## On the Windows side

ws-creator writes one SSH host per machine in `~\.ssh\ws-creator\<name>.conf`, included from
`~\.ssh\config` (`Include ws-creator/*.conf`). The host goes through
`wsl.exe -d <name> --exec nc 127.0.0.1 <port>`: the distro starts on demand and no port is
exposed on the network.

## In the distro

| Path | What |
|---|---|
| `/etc/ws-creator-profile` | marks a distro created by ws-creator; `purge` refuses without it |
| `/var/lib/ws-creator/cloud-config/` | the fragments and `user-data.yaml` of the last run |
| `/var/lib/cloud/seed/nocloud/` | the NoCloud seed assembled from them |
| `/etc/ws-creator/hooks` | machine-wide git hooks (`core.hooksPath`) |
| `/etc/ws-creator/guard.conf` | guardrail settings, from the machine's `files/` |
