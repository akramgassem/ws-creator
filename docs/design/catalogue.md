# Design: template catalog and `ws-creator init`

Status: proposed · target: 0.2.0

## Context

To create a machine, the user copies `examples/agent-sandbox` (missing from the installed
module) and fixes the user, SSH key, port, subnet and `Location` by hand. Mistakes only show
up at `new`.

## Goals

- A public catalog shipped with the module: `dev` and `agent-sandbox`.
- Personal or team catalogs, in the same format: a local folder or a GitHub repo.
- `ws-creator init <template> <name>` produces a valid machine, with no manual fixes.
- The machine belongs to the user; fragments keep following the module.
- `list` shows where each template and each machine comes from.

Out of scope: a minimal template (`wsl --install` is enough), updating a machine when its
template changes.

## Mechanism

### A template is a valid machine

Same format as a machine (`machine.psd1`, `user-data.yaml`, `AGENTS.md`, `files/`), with
example values, and a `Description` key shown by `list`. No template syntax. A machine
becomes a template by copying it; each template is tested with `Get-Machine`.
`examples/` is replaced by `src/WsCreator/templates/`.

### Sources

A catalog is a folder of templates. `WS_CREATOR_TEMPLATES` lists several of them, separated
by `;`, each one being:

- a local path: `D:\templates`;
- a git repo: `https://github.com/acme/ws-templates`, optionally `#<branch|tag>`.
  It is cloned into `%LOCALAPPDATA%\ws-creator\catalogs\github.com\acme\ws-templates`;
  `list` reads this clone offline, `init` and `list -Refresh` update it (`git fetch`).

The module is the last source: its `templates\` folder.

Each template has a single source, shown as it really is: the template's local path, or its
path on GitHub (`github.com/acme/ws-templates/api`). A name found in several sources: the
first one wins (like `PATH`), `list` shows the others as shadowed.

### `ws-creator init <template> <name>`

1. Refuses if `WS_CREATOR_MACHINES\<name>\` exists.
2. Copies the template into a temporary folder.
3. Computes the identity values:

   | Value | Default | Parameter |
   |---|---|---|
   | user | `$env:USERNAME` in lowercase, reduced to `[a-z0-9_-]` | `-User` |
   | SSH key | `~\.ssh\id_ed25519.pub` | `-PublicKey` |
   | SSH port | first free one from 2222 (machines and Windows ports) | `-Port` |
   | podman subnet | first free `10.89.N.0/24` | `-Subnet` |
   | `Location` | `WS_CREATOR_LOCATION`, otherwise `C:\WSL` | `-Location` |

4. Rewrites them where `Get-Machine` checks them: `name:`, `default=`, `hostname=`,
   `AllowUsers`, `Port`, `default_subnet`, `ssh_authorized_keys`, `/home/<u>/`,
   `owner: <u>:<u>`, and the `machine.psd1` keys. Replacements are anchored on these
   patterns; a line still holding the old user is reported.
5. Records the provenance in `machine.psd1`:

   ```powershell
   Template        = 'api'
   TemplateSource  = 'github.com/acme/ws-templates/api'   # the source shown by list
   TemplateVersion = '3f2a1c9'                            # commit, or module version
   TemplateHash    = 'sha256:…'                           # hash of the files written by init
   ```

   `TemplateHash` lets `list` tell whether the machine was modified since it was copied.
6. Validates (`Get-Machine`, `Test-MachineConflict`); on failure, nothing is written.

Without `-Apply`: dry run.

### `ws-creator list`

```
Templates
  api             Node API and Postgres
                  github.com/acme/ws-templates/api
  dev             My work machine
                  D:\templates\dev
  dev (shadowed)  Work machine: sudo, podman, git guardrails
                  ~\Documents\PowerShell\Modules\WsCreator\0.2.0\templates\dev
  agent-sandbox   Sandbox for an agent: no sudo, no Windows disk
                  ~\Documents\PowerShell\Modules\WsCreator\0.2.0\templates\agent-sandbox

Machines (%APPDATA%\ws-creator\machines)
  my-machine      copied from D:\templates\dev, modified since
  api-service     copied from github.com/acme/ws-templates/api @ 3f2a1c9
  legacy          written by hand

WSL distros
  …
```

"modified since": the files no longer match `TemplateHash`.

## Ownership

After `init`, the user changes their machine freely (packages, tools, `sudo`, `wsl.conf`,
fragments) and reapplies with `apply`. `Update-PSResource WsCreator` updates fragments,
`files/` and `modules/`, never the copy. Rule for templates: put as little as possible in
them, and turn what several of them share into a fragment.

## Module templates

| Template | Fragments, modules | Specifics |
|---|---|---|
| `dev` | base, mise, guard, podman, ssh · agent | sudo, podman group, common tools (gh, node, python, uv, jq, rg, fd, yq, gitleaks, lefthook, docker-compose, chezmoi) |
| `agent-sandbox` | base, mise, guard, podman, ssh · agent | no sudo and no podman group, `automount` and `interop` turned off |

## Open questions

- `ws-creator diff <machine>` based on the provenance, like `copier update`.
- Fragments brought by a personal catalog.
- `AGENTS.md` of the `dev` template.

## Plan

1. `templates/` (`dev`, `agent-sandbox`), `Description` key, `examples/` removed.
2. Sources (local paths, cached git repos), `list` in three sections with the real source.
3. `init`: values, rewriting, provenance, validation, dry run.
4. Pester tests for the templates and `init`.
5. `Get-Help` help, README, 0.2.0.
