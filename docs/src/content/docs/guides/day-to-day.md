---
title: Day-to-day use
tableOfContents: false
description: Apply, stop, rebuild, purge.
sidebar:
  order: 1
---

```powershell
ws-creator apply my-machine -Apply              # after editing the machine folder
ws-creator apply my-machine -Only mise -Apply   # one fragment only
ws-creator status my-machine
ws-creator stop my-machine -Apply               # never wsl --terminate
ws-creator image my-machine -Apply              # base image: faster rebuilds
ws-creator purge my-machine -Apply              # then: new
```

- **cloud-init only adds.** To remove a package or a permission: purge, then new.
- **purge** refuses while `~/src` or `~/scratch` holds unpushed work (`-Force` to override).
  Then revoke the GitHub CLI token, unless it was `--expiring`.
- **stop**, not `wsl --terminate`: a killed container leaves NAT rules behind
  (`wsl --shutdown` clears them).
- **Project services** live in the project's `compose.yaml`, with `network_mode: host`.
