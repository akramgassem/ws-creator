#!/usr/bin/env bash
set -euo pipefail
: "${WS_CREATOR_USER:?Environment variable WS_CREATOR_USER is required}"
: "${WS_CREATOR_AGENT_MD_B64:?AgentInstructions is missing in machine.psd1}"

# Instructions lues par Claude Code à chaque session sur cette machine
# (~/.claude/CLAUDE.md = mémoire utilisateur). Réécrites à chaque passage : la machine (<WS_CREATOR_MACHINES>/<nom>/) fait foi.
home=$(user_home)

as_user mkdir -p "$home/.claude/skills" "$home/src" "$home/scratch"
echo "$WS_CREATOR_AGENT_MD_B64" | base64 -d | as_user tee "$home/.claude/CLAUDE.md" >/dev/null

# Skills de la machine (/menage) : copiées par ws-creator avec files/ (donc par un passage cloud-init,
# ex. -Only guard,agent), réécrites ici. Les autres skills de ~/.claude/skills ne sont pas touchées.
for skill in /usr/local/share/ws-creator/claude/skills/*/; do
    [ -d "$skill" ] || continue
    dest="$home/.claude/skills/$(basename "$skill")"
    as_user rm -rf "$dest"
    as_user cp -r "$skill" "$dest"
done

# Adaptateur Claude Code : au démarrage d'une session, l'état de la machine (module guard)
# entre dans le contexte. machine-prune-branch, qui vérifie lui-même que la PR est fusionnée,
# est autorisé sans confirmation : une règle explicite passe avant le classifieur du mode auto,
# qui refuse sinon git branch -D et git push --delete. Seules les entrées ws-creator de
# ~/.claude/settings.json sont réécrites.
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
