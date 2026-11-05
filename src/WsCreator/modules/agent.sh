#!/usr/bin/env bash
set -euo pipefail
: "${WS_CREATOR_USER:?Environment variable WS_CREATOR_USER is required}"
: "${WS_CREATOR_AGENT_MD_B64:?AgentInstructions is missing in machine.psd1}"

# Instructions read by Claude Code in every session on this machine
# (~/.claude/CLAUDE.md = user memory). Rewritten on every run: the machine (<WS_CREATOR_MACHINES>/<name>/) is the source of truth.
home=$(user_home)

as_user mkdir -p "$home/.claude/skills" "$home/src" "$home/scratch"
echo "$WS_CREATOR_AGENT_MD_B64" | base64 -d | as_user tee "$home/.claude/CLAUDE.md" >/dev/null

# The machine's skills (/tidy): copied by ws-creator with files/ (so by a cloud-init run,
# e.g. -Only guard,agent), rewritten here. Other skills in ~/.claude/skills are left alone.
for skill in /usr/local/share/ws-creator/claude/skills/*/; do
    [ -d "$skill" ] || continue
    dest="$home/.claude/skills/$(basename "$skill")"
    as_user rm -rf "$dest"
    as_user cp -r "$skill" "$dest"
done

# Claude Code adapter: at session start, the machine state (guard module) enters the
# context. machine-prune-branch, which checks by itself that the PR is merged, is allowed
# without confirmation: an explicit rule wins over the auto mode classifier, which otherwise
# refuses git branch -D and git push --delete. Only the ws-creator entries of
# ~/.claude/settings.json are rewritten.
as_user python3 -I - "$home/.claude/settings.json" <<'PY'
import json, os, sys
path = sys.argv[1]
settings = json.load(open(path)) if os.path.exists(path) else {}
cmd = "command -v machine-state >/dev/null && machine-state || true"
start = [h for h in settings.setdefault("hooks", {}).get("SessionStart", [])
         if "machine-state" not in json.dumps(h)]
start.append({"hooks": [{"type": "command", "command": cmd}]})
settings["hooks"]["SessionStart"] = start
rule = "Bash(machine-prune-branch *)"
allow = [r for r in settings.setdefault("permissions", {}).get("allow", [])
         if not r.startswith("Bash(machine-prune-branch")]
settings["permissions"]["allow"] = allow + [rule]
json.dump(settings, open(path, "w"), indent=2)
PY
