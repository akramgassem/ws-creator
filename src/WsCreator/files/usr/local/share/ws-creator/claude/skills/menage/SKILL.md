---
name: menage
description: Ramasse les miettes laissées par les sessions sur cette machine (branches dont la PR est fusionnée, worktrees orphelins, serveurs de dev oubliés, dossiers de scratch jetables, conteneurs sans projet), sans toucher au travail d'une autre session. À lancer à la fin d'une tâche, avant de dire qu'elle est terminée, ou quand machine-state annonce des « Miettes ».
---

# Ménage de la machine

Plusieurs sessions travaillent sur cette machine, souvent dans les mêmes dépôts. Ramasse ce
que cette session a laissé, et ce que personne ne réclame plus. Ne touche pas au reste : signale-le.

## 1. Détecter

```bash
for g in $(find ~/src -maxdepth 5 -name .git -prune); do git -C "${g%/.git}" fetch --prune --quiet origin 2>/dev/null; done
machine-crumbs
```

`fetch --prune` ne met à jour que les références distantes : jamais `pull`, `checkout` ni
`switch`, une autre session peut travailler dans le checkout. `machine-crumbs` interroge GitHub
(une à deux minutes) et ne supprime rien. Chaque ligne « ~ » dit à qui elle appartient :
« cette session », « session <id> active », « session <id> terminée », ou rien.

**Une ligne « session <id> active » appartient à une autre session : ne rien y faire, la citer
dans le compte rendu.**

## 2. Nettoyer, par sorte de miette

- **Branche « PR #n fusionnée »** : `machine-prune-branch <dépôt> <branche>` (dépôt : chemin
  absolu, `~/` + le chemin de la ligne). Il revérifie avec `gh` que la PR est `MERGED`, qu'aucune
  n'est ouverte et que tous les commits, locaux et sur origin, sont dans la PR. Ensuite seulement
  il supprime la branche locale et la branche distante. Pas d'autre commande pour supprimer une
  branche : ni `git branch -D`, ni `git push --delete`. S'il répond « gardée : … », la raison va
  dans le compte rendu.
- **Branche « distante supprimée » sans PR fusionnée** : ne pas la supprimer. La citer avec les
  commits que `machine-leftovers` lui trouve.
- **Branche « extraite dans … »** : ne pas la supprimer (git refuserait). Son worktree passe d'abord.
- **Worktree « disparu »** : `git -C <dépôt> worktree prune`.
- **Worktree d'une session terminée** : `git -C <dépôt> worktree remove <chemin>`, sans `--force`.
  S'il a des modifications non commitées, ne rien faire : les signaler à l'utilisateur.
- **Serveur** « dossier courant supprimé », « dans le scratchpad d'une session terminée » ou
  « lancé par cette session » : `kill <PID>`, puis vérifier que le port est libre (`ss -ltn`).
  Un serveur lié à une session active, ou d'origine douteuse, se liste : ne pas l'arrêter.
- **Dossier de scratch jetable** : demander à l'utilisateur avant de le supprimer, avec la ligne
  du README. S'il contient un dépôt ou un worktree, d'abord `machine-leftovers` : une ligne « ! »
  pour ce dossier, et on garde. Un worktree s'enlève par `git worktree remove`, pas par `rm`.
- **Conteneur sans projet** : demander à l'utilisateur avant `docker rm` (ou `docker compose down`).

## 3. Garde-fous

- Ne jamais toucher au travail non commité d'un dépôt, ni changer de branche dans un checkout.
- Jamais `--no-verify`, jamais `--force` : un refus d'un hook ou de git se signale, il ne se contourne pas.
- Dans le doute sur l'origine d'une miette, la lister sans y toucher.

## 4. Finir

```bash
machine-crumbs --local
machine-leftovers
```

Compte rendu court, en trois parties : ce qui a été supprimé ; ce qui reste, avec la raison
(autre session active, travail non poussé, refus de `machine-prune-branch`, attente d'une
réponse) ; et les lignes « ! » de `machine-leftovers`, qui seules feraient refuser la purge.
