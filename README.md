# ws-creator

[![ci](https://github.com/akramgassem/ws-creator/actions/workflows/ci.yml/badge.svg)](https://github.com/akramgassem/ws-creator/actions/workflows/ci.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/WsCreator)](https://www.powershellgallery.com/packages/WsCreator)

Workspace creator for developers on Windows: a folder describes your WSL workspace,
ws-creator builds it (cloud-init, then a few scripts), updates it and deletes it.

**Documentation: https://akramgassem.github.io/ws-creator/**

```powershell
Install-PSResource WsCreator
ws-creator init dev my-machine -Apply   # a machine folder from a template, with your user and key
ws-creator new my-machine -Apply        # the WSL distro, provisioned by cloud-init
ssh my-machine                          # or: ws-creator code my-machine
```

Requirements: Windows 11, WSL 2 in mirrored networking mode, PowerShell 7.4+.

## Why

- **A quiet sandbox per project**: no tool, version or setting leaks between projects or onto Windows.
- **Many toolchains, no clutter**: each workspace has only what its work needs.
- **A fresh machine, on demand**: test a setup, an onboarding guide or a release from scratch.
- **Agents on a leash**: coding agents without sudo or Windows disk, behind git guardrails.
- **Throw away, start over**: purge and recreate; purge refuses while work is unpushed.
- **One git identity per workspace**: personal and work accounts never mix.
- **Plain files**: standard cloud-config, versioned and shared as templates.

    ws-creator init   <template> <name> [-Apply]         machine folder from a template
    ws-creator new    <machine> [-Apply]                 creates the distro and applies everything
    ws-creator apply  <machine> [-Only a,b] [-Apply]     reapplies fragments and modules
    ws-creator purge  <machine> [-Apply] [-Force]        deletes the distro (then new to rebuild it)
    ws-creator stop   <machine> [-Apply]                 stops cleanly (containers, then the distro)
    ws-creator image  <machine> [-Apply]                 builds the base image (base + mise)
    ws-creator status <machine>                          distro, disk, cloud-init, containers, gh
    ws-creator code   <machine>                          opens VS Code on the machine's ~/src
    ws-creator doctor                                    WSL, network, Falcon, conflicts, key permissions
    ws-creator list   [-Refresh]                         templates, machines (and where they come from), distros

Without `-Apply`: dry run, nothing is executed or written. `Get-Help <function> -Full` for
each command.

![ws-creator architecture](docs/src/assets/architecture.svg)

## Learn more

- [Getting started](https://akramgassem.github.io/ws-creator/getting-started/)
- [Your own templates](https://akramgassem.github.io/ws-creator/guides/templates/)
- [Commands](https://akramgassem.github.io/ws-creator/reference/commands/)
- [Architecture](https://akramgassem.github.io/ws-creator/explanation/architecture/)
- [Contributing](https://akramgassem.github.io/ws-creator/contributing/)

## License

[MIT](LICENSE)
