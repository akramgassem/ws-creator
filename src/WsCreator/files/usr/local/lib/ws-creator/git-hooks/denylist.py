"""Noms interdits : sha256 de mots (et de paires de mots) en minuscules, une empreinte par
ligne dans /etc/ws-creator/denylist.sha256, '#' pour commenter. Sont cherchés aussi les
morceaux des mots composés (« nom-produit » est cherché aussi sous « nom » et « produit »).
Texte sur l'entrée standard, code 1 si un nom est trouvé."""
import hashlib
import re
import sys

try:
    with open("/etc/ws-creator/denylist.sha256") as f:
        hashes = {l.strip() for l in f if l.strip() and not l.startswith("#")}
except FileNotFoundError:
    sys.exit(0)

words = re.findall(r"[a-z0-9]+(?:-[a-z0-9]+)*", sys.stdin.read().lower())
found = set()
for i, w in enumerate(words):
    candidates = [w, *w.split("-")]
    if i + 1 < len(words):
        candidates.append(w + " " + words[i + 1])
    for c in candidates:
        h = hashlib.sha256(c.encode()).hexdigest()
        if h in hashes:
            found.add(h[:10])

if found:
    print(f"ws-creator guard : nom interdit dans {sys.argv[1]} (hash {', '.join(sorted(found))}) ;"
          " anonymiser, voir les règles de la machine", file=sys.stderr)
    sys.exit(1)
