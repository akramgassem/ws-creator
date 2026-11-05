"""Forbidden names: sha256 of lowercase words (and word pairs), one hash per line in
/etc/ws-creator/denylist.sha256, '#' for comments. Parts of compound words are checked too
("product-name" is also checked as "product" and "name").
Text on stdin, exit code 1 if a name is found."""
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
    print(f"ws-creator guard: forbidden name in {sys.argv[1]} (hash {', '.join(sorted(found))});"
          " anonymize it, see the machine's rules", file=sys.stderr)
    sys.exit(1)
