---
title: WSL networking and EDRs
description: Shared ports, and fragments that survive an EDR.
sidebar:
  order: 3
---

## Mirrored networking

Windows and every distro share `127.0.0.1` and its ports.

- SSH ports and podman subnets are unique per machine; ws-creator checks.
- sshd listens on loopback only; Windows reaches it through `wsl.exe` and `nc`.
- Published container ports are not reachable from the distro: use `network_mode: host`.

## Under an EDR

CrowdStrike Falcon may confine systemd with no delegated cgroup controller. The fragments
work with or without it: no systemd user session, podman as root through its socket,
no `pids` limit, no `--memory` or `--cpus`.

## Known issues

- WSL 2.6.1 warns `Failed to start the systemd user session` at login: harmless.
- `DOCKER_HOST` is set through PAM: present in ssh and VS Code, not in `wsl --exec`.
- `ssh <machine> 'cmd'` without `-t` prints staircase output in the Windows console.
- A Claude session keeps its Windows connectors: turn them off for an agent.
