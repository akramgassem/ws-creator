---
title: Your own templates
description: Personal and team catalogs, local or on GitHub.
sidebar:
  order: 2
---

A template is a machine folder with a `Description` in `machine.psd1`. A catalog is a
folder of templates.

```powershell
$env:WS_CREATOR_TEMPLATES = 'D:\templates;https://github.com/acme/ws-templates#main'
ws-creator list -Refresh
```

- Catalogs are searched in order, the module's last. First match wins; others show as
  *shadowed*.
- Git catalogs are cloned to `%LOCALAPPDATA%\ws-creator\catalogs`. `list` works offline;
  `init` and `list -Refresh` fetch.
- `init` rewrites only identity values: user, hostname, SSH port and key, subnet, `Location`.

## Provenance

`init` records where a machine comes from; `list` shows it:

```text
my-machine     copied from D:\templates\dev, modified since
api-service    copied from github.com/acme/ws-templates/api @ 3f2a1c9
legacy         written by hand
```
