---
title: Your own templates
description: Personal and team template catalogs, local or on GitHub, and how list shows where a machine comes from.
sidebar:
  order: 2
---

A template is a valid machine folder with a one-line `Description` in `machine.psd1`. A
catalog is a folder of templates. There is no template syntax: `init` copies the folder and
rewrites only the identity values (user, hostname, SSH port and key, podman subnet, disk
location).

## Make a template

Copy a machine you like into a catalog folder, then add a description:

```powershell
@{
    Description = 'API work: Node, Postgres client, sudo'
    BaseDistribution = 'Ubuntu-24.04'
    # ...the rest of machine.psd1, unchanged
}
```

Keep templates small: what several templates share belongs in a fragment.

## Use catalogs

`WS_CREATOR_TEMPLATES` lists catalogs separated by `;`. Each one is a local folder or a git
repo, optionally with `#<branch|tag>`:

```powershell
$env:WS_CREATOR_TEMPLATES = 'D:\templates;https://github.com/acme/ws-templates#main'
ws-creator list -Refresh
```

- Git catalogs are cloned into `%LOCALAPPDATA%\ws-creator\catalogs\`. `list` reads the clone
  without network; `init` and `list -Refresh` fetch it. A private repo needs git credentials
  on Windows (Git Credential Manager).
- Catalogs are searched in order, then the module's own templates. The first one holding a
  name wins; `list` shows the others as shadowed.

Set the variable in your PowerShell profile to keep it.

## Where a machine comes from

`init` records the provenance in the new `machine.psd1`:

```powershell
Template        = 'api'
TemplateSource  = 'github.com/acme/ws-templates/api'
TemplateVersion = '3f2a1c9'        # commit of a git catalog, or the module version
TemplateHash    = 'sha256:...'     # hash of the files init wrote
```

`list` uses it:

```text
Machines (~\AppData\Roaming\ws-creator\machines)
  my-machine      copied from D:\templates\dev, modified since
  api-service     copied from github.com/acme/ws-templates/api @ 3f2a1c9
  legacy          written by hand
```

"modified since" means the files no longer match `TemplateHash`. Updating the module never
touches your machines: they keep their copy, and fragments and modules follow the module.
