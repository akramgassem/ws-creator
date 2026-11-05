# agent-sandbox machine: a sandbox for an agent

Throwaway Linux machine (WSL distro created by ws-creator), with no access to the Windows
disk or Windows programs. Anything that must survive is pushed or handed to the user.

## Layout

- Repos: `~/src/<host>/<owner>/<repo>`
- Throwaway experiments: `~/scratch/<topic>`
- Never a work file directly in `~`

## Guardrails

- `machine-state` (run at the start of each session): repo state, crumbs
- Before saying a piece of work is done: `/tidy` (the session's crumbs, then `machine-leftovers`,
  what would be lost)
- Deleting a branch: `machine-prune-branch <repo> <branch>`, which checks that its PR is merged
- The machine's git hooks (secrets, push to a merged PR): fix what they refuse,
  never `--no-verify` without explicit agreement

## Limits (on purpose)

- No `sudo` and no containers: the user is not an administrator of the machine.
  A package or tool is missing? Tell the user, who adds it to the machine in ws-creator
- User tools through mise only (in the project's `mise.toml`)

## Rules

- Browser and app connectors (Chrome...): they act on the Windows side, with the user's
  sessions, outside this sandbox. Do not use them unless explicitly asked
- Never commit a secret; `.env` always in `.gitignore`
