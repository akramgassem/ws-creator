---
title: WSL networking and EDRs
description: Why ports and subnets are unique per machine, and the choices that keep ws-creator working under an EDR.
sidebar:
  order: 3
---

## One network stack for everything

With WSL mirrored networking, Windows and every distro share `127.0.0.1` and the ports. A
port taken on Windows (a local Postgres on 5432) is taken for every machine, and two
machines cannot use the same SSH port or podman subnet. `init` picks free ones; `new` and
`apply` refuse duplicates (`Test-MachineConflict`). Two projects starting a service on the
same port on two machines at once still conflict.

sshd listens on `127.0.0.1` only: with mirrored networking, `0.0.0.0` would expose it on the
LAN. Windows reaches it through `wsl.exe` and `nc`.

Known effects of mirrored networking:

- podman's iptables redirection to `127.0.0.1` does not work (a published port answers from
  Windows, not from the distro): project services use `network_mode: host`.
- a container killed by `wsl --terminate` leaves its NAT rules active: stop with
  `ws-creator stop`, or `wsl --shutdown` to clean up.

## Under an EDR (CrowdStrike Falcon)

An EDR such as Falcon (`ws-creator doctor` detects it) may put systemd under
`/sys/fs/cgroup/sensor.falcon` with no delegated controller. The fragments are written to
work with or without it:

- no systemd user session: no linger, journald broadcast turned off;
- podman as root, driven through the socket `/run/podman/podman.sock` and the podman group;
- `pids_limit = 0`, and no `--memory` or `--cpus` on containers.

ws-creator does not touch the EDR's configuration.

## Other known issues

- WSL 2.6.1 prints `Failed to start the systemd user session for '<user>'` at every login;
  no consequence for ws-creator.
- `CONTAINER_HOST` and `DOCKER_HOST` are in `/etc/environment`, read by PAM (ssh, VS Code)
  but not by `wsl --exec`.
- `wsl -- <cmd>` has bash reinterpret the command: ws-creator uses `--exec`.
- PowerShell appends `\r\n` to what it pipes to a program: modules go through `tr -d '\r'`.
- Windows OpenSSH requires private ACLs on the key and `~\.ssh\ws-creator`.
- `ssh <machine> 'cmd'` without `-t` gives staircase output in the Windows console.
- From a clone, `pwsh -File ws-creator.ps1 ... -Only a,b` passes `a,b` as one value: run
  `.\ws-creator.ps1` from a PowerShell session, or the installed `ws-creator`.
- A Claude session keeps its Windows connectors (Chrome...): isolation is the machine's, not
  the app's; turn them off for an agent.
