---
title: A machine folder
description: machine.psd1, user-data.yaml and files/, and what ws-creator checks in them.
---

A machine is a folder `<WS_CREATOR_MACHINES>\<name>\`. The folder name is the distro name
and the hostname.

```text
my-machine/
  machine.psd1      Windows side: base image, disk, fragments, modules, unique values
  user-data.yaml    the machine itself, in plain cloud-config
  AGENTS.md         optional: instructions for coding agents (AgentInstructions)
  files/            optional: system files specific to the machine
```

## machine.psd1

The Windows side only, and the values that must be unique across machines.

| Key | Required | Role |
|---|---|---|
| `BaseDistribution` | yes | WSL image (`wsl --list --online`) |
| `Location` | yes | folder of the virtual disk (`<Location>\<name>`) |
| `CloudConfig` | yes | fragments, in order; `user-data.yaml` comes last |
| `Modules` | no | scripts run after cloud-init, in order |
| `PodmanSubnet` | with `podman` | /24 subnet for containers, **unique per machine** |
| `Ssh` | with `ssh` | `Port` (**unique per machine**) and `PublicKey` (file in `~\.ssh`) |
| `AgentInstructions` | no | file of this folder copied to `~/.claude/CLAUDE.md` (agent module) |
| `Description` | templates only | one line shown by `list` |
| `Template`, `TemplateSource`, `TemplateVersion`, `TemplateHash` | written by `init` | provenance shown by `list` |

## user-data.yaml

Plain cloud-config, specific to the machine: `users` (and so the permissions: `sudo` group
and rule, or `sudo: null`), `/etc/wsl.conf` (hostname, default user, Windows disk, interop),
extra packages, and the mise config (`~/.config/mise/config.toml`, with `defer: true`).

ws-creator reads the user from `default=` in `wsl.conf` and checks that:

- the user is in `users`, and `hostname=` is the folder name;
- with the `ssh` fragment: `Port` and `AllowUsers` in
  `/etc/ssh/sshd_config.d/60-ws-creator-machine.conf` match `Ssh.Port` and the user, and the
  `Ssh.PublicKey` key is in `ssh_authorized_keys` (without its comment);
- with the `podman` fragment: `default_subnet` in
  `/etc/containers/containers.conf.d/60-ws-creator-machine.conf` matches `PodmanSubnet`;
- with the `mise` fragment: `~/.config/mise/config.toml` is written.

Membership of the `podman` group gives access to the podman socket, so root rights.

## files/

System files specific to the machine, copied as is, path = destination: for example
`files/etc/ws-creator/guard.conf` and `files/etc/ws-creator/denylist.sha256` for the
[guardrails](../../explanation/guardrails/). Never under `/home`: the folder would be
created as root before the user exists; what goes to the user goes through `user-data.yaml`.

Nothing personal belongs in a machine: the git identity and personal settings live in the
user's dotfiles (chezmoi), which follow them to every machine.
