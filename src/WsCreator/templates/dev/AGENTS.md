# Work machine

Linux machine (WSL distro created by ws-creator) that can be deleted and rebuilt at any time.
Anything that must survive is pushed; nothing important stays only here.

## Layout

- Repos: `~/src/<host>/<owner>/<repo>`, e.g. `gh repo clone <owner>/<repo> ~/src/github.com/<owner>/<repo>`
- Throwaway experiments: `~/scratch/<topic>`, with a one-line `README` saying whether to keep it
  ("throwaway": `/tidy` offers to remove it after 7 days without changes)
- Never a work file directly in `~`
- To work in a repo: open the session there, or first read its `AGENTS.md`

## Already set up

- Tools through mise: node (LTS), python 3.12 + uv, gh, jq, rg, fd, yq, gitleaks, lefthook, chezmoi
- Containers: podman as root, Docker compatible (`docker`, `docker compose`, `DOCKER_HOST`)
- Personal config (git identity...): dotfiles applied by chezmoi, after `gh auth login`

## Guardrails (for everything that goes through git)

- `machine-state` (run at the start of each session): containers, `gh`, state of each repo, crumbs
- Before saying a piece of work is done: `/tidy` (the session's crumbs, then `machine-leftovers`,
  what would be lost)
- Deleting a branch: `machine-prune-branch <repo> <branch>`, which checks that its PR is merged
- The machine's git hooks (secrets, push to a merged PR): fix what they refuse,
  never `--no-verify` without explicit agreement

## Rules

- Tool versions specific to a project: in ITS `mise.toml`, never global
- Dependencies: in the project, not on the machine
- A tool is missing for the whole machine? Tell the user: the machine is described in
  ws-creator, on the Windows side. Anything installed here by hand disappears on rebuild
- Services (databases...): in the project's `compose.yaml`, with `network_mode: host`
  (with WSL mirrored, a port published by podman cannot be reached from the machine)
- No memory/CPU limit on containers (`--memory`, `--cpus` may fail)
- Never commit a secret; `.env` always in `.gitignore`
- Browser and app connectors (Chrome...): they act on the Windows side, with the user's
  sessions, outside this machine. Only use them when explicitly asked
