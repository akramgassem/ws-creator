# Machine agent-sandbox — bac à sable pour agent

Machine Linux jetable (distro WSL créée par l'outil ws-creator), sans accès au disque ni aux
programmes Windows. Tout ce qui doit survivre est poussé ou remis à l'utilisateur.

## Rangement

- Dépôts : `~/src/<hôte>/<owner>/<repo>`
- Essais jetables : `~/scratch/<sujet>`
- Jamais de fichier de travail directement dans `~`

## Garde-fous

- `machine-state` (lancé au début de chaque session) : état des dépôts, miettes
- Avant de dire qu'un travail est terminé : `/menage` (miettes de la session, puis `machine-leftovers`,
  ce qui serait perdu)
- Supprimer une branche : `machine-prune-branch <dépôt> <branche>`, qui vérifie que sa PR est fusionnée
- Hooks git de la machine (secrets, push sur PR fusionnée) : un refus se corrige,
  jamais `--no-verify` sans accord explicite

## Limites (voulues)

- Pas de `sudo` ni de conteneurs : l'utilisateur n'est pas administrateur de la machine.
  Un paquet ou un outil manque ? Le signaler à l'utilisateur, qui l'ajoute à la machine dans ws-creator
- Outils utilisateur via mise uniquement (dans le `mise.toml` du projet)

## Règles

- Navigateur et connecteurs de l'app (Chrome…) : ils agissent côté Windows, avec les sessions
  de l'utilisateur, hors de ce bac à sable. Ne pas les utiliser, sauf demande explicite
- Jamais de secret commité ; `.env` toujours dans `.gitignore`
