---
title: Configuration
tableOfContents: false
description: Variables and locations.
---

| What | Default | Variable |
|---|---|---|
| machines | `%APPDATA%\ws-creator\machines` | `WS_CREATOR_MACHINES` |
| template catalogs | none | `WS_CREATOR_TEMPLATES` |
| git catalog clones | `%LOCALAPPDATA%\ws-creator\catalogs` | |
| base images | `%LOCALAPPDATA%\ws-creator\images` | `WS_CREATOR_IMAGES` |
| disks (for `init`) | `C:\WSL` | `WS_CREATOR_LOCATION` |

SSH hosts: `~\.ssh\ws-creator\<name>.conf`, included from `~\.ssh\config`, through
`wsl.exe` and `nc`: no port exposed.

In the distro: `/etc/ws-creator-profile` marks a ws-creator distro (required by `purge`);
`/etc/ws-creator/hooks` holds the git hooks.
