# Design : catalogue de modèles et `ws-creator init`

Statut : proposé · cible : 0.2.0

## Contexte

Pour créer une machine, l'utilisateur copie `examples/agent-sandbox` (absent du module installé)
et corrige à la main l'utilisateur, la clé SSH, le port, le sous-réseau et `Location`. Les
erreurs n'apparaissent qu'à `new`.

## Objectifs

- Un catalogue public livré avec le module : `dev` et `agent-sandbox`.
- Des catalogues personnels ou d'équipe, au même format : un dossier local ou un dépôt GitHub.
- `ws-creator init <modèle> <nom>` produit une machine valide, sans correction manuelle.
- La machine appartient à l'utilisateur ; les fragments continuent de suivre le module.
- `list` montre d'où vient chaque modèle et chaque machine.

Hors périmètre : un modèle minimal (`wsl --install` suffit), la mise à jour d'une machine quand
son modèle change.

## Mécanisme

### Un modèle est une machine valide

Même format qu'une machine (`machine.psd1`, `user-data.yaml`, `AGENTS.md`, `files/`), avec des
valeurs d'exemple, et une clé `Description` affichée par `list`. Pas de syntaxe de modèle.
Une machine devient un modèle par copie ; chaque modèle se teste avec `Get-Machine`.
`examples/` est remplacé par `src/WsCreator/templates/`.

### Sources

Un catalogue est un dossier de modèles. `WS_CREATOR_TEMPLATES` en liste plusieurs, séparés par
`;`, chacun étant :

- un chemin local : `D:\templates` ;
- un dépôt git : `https://github.com/acme/ws-templates`, éventuellement `#<branche|tag>`.
  Il est cloné dans `%LOCALAPPDATA%\ws-creator\catalogs\github.com\acme\ws-templates` ;
  `list` lit ce clone sans réseau, `init` et `list -Refresh` le mettent à jour (`git fetch`).

Le module est la dernière source : son dossier `templates\`.

Chaque modèle n'a qu'une source, affichée telle qu'elle est réellement : le chemin local du
modèle, ou son chemin sur GitHub (`github.com/acme/ws-templates/api`). Un nom présent dans
plusieurs sources : la première gagne (comme `PATH`), `list` affiche les autres comme masquées.

### `ws-creator init <modèle> <nom>`

1. Refuse si `WS_CREATOR_MACHINES\<nom>\` existe.
2. Copie le modèle dans un dossier temporaire.
3. Calcule les valeurs d'identité :

   | Valeur | Par défaut | Paramètre |
   |---|---|---|
   | utilisateur | `$env:USERNAME` en minuscules, réduit à `[a-z0-9_-]` | `-User` |
   | clé SSH | `~\.ssh\id_ed25519.pub` | `-PublicKey` |
   | port SSH | premier libre dès 2222 (machines et ports Windows) | `-Port` |
   | sous-réseau podman | premier `10.89.N.0/24` libre | `-Subnet` |
   | `Location` | `WS_CREATOR_LOCATION`, sinon `C:\WSL` | `-Location` |

4. Les réécrit aux emplacements que `Get-Machine` vérifie : `name:`, `default=`, `hostname=`,
   `AllowUsers`, `Port`, `default_subnet`, `ssh_authorized_keys`, `/home/<u>/`,
   `owner: <u>:<u>`, et les clés de `machine.psd1`. Remplacements ancrés sur ces motifs ; une
   ligne contenant encore l'ancien utilisateur est signalée.
5. Note la provenance dans `machine.psd1` :

   ```powershell
   Template        = 'api'
   TemplateSource  = 'github.com/acme/ws-templates/api'   # la source affichée par list
   TemplateVersion = '3f2a1c9'                            # commit, ou version du module
   TemplateHash    = 'sha256:…'                           # empreinte des fichiers écrits par init
   ```

   `TemplateHash` permet à `list` de dire si la machine a été modifiée depuis sa copie.
6. Valide (`Get-Machine`, `Test-MachineConflict`) ; en cas d'échec, rien n'est écrit.

Sans `-Apply` : aperçu.

### `ws-creator list`

```
Modèles
  api             API Node et Postgres
                  github.com/acme/ws-templates/api
  dev             Ma machine de travail
                  D:\templates\dev
  dev (masqué)    Machine de travail : sudo, podman, garde-fous git
                  ~\Documents\PowerShell\Modules\WsCreator\0.2.0\templates\dev
  agent-sandbox   Bac à sable pour agent : ni sudo, ni disque Windows
                  ~\Documents\PowerShell\Modules\WsCreator\0.2.0\templates\agent-sandbox

Machines (%APPDATA%\ws-creator\machines)
  ma-machine      copiée de D:\templates\dev, modifiée depuis
  service-api     copiée de github.com/acme/ws-templates/api @ 3f2a1c9
  ancienne        écrite à la main

Distros WSL
  …
```

« modifiée depuis » : les fichiers ne correspondent plus à `TemplateHash`.

## Appropriation

Après `init`, l'utilisateur modifie librement sa machine (paquets, outils, `sudo`,
`wsl.conf`, fragments) et rejoue avec `apply`. `Update-PSResource WsCreator` met à jour
fragments, `files/` et `modules/`, jamais la copie. Règle pour les modèles : y mettre le moins
possible, et passer en fragment ce qui sert à plusieurs.

## Modèles du module

| Modèle | Fragments, modules | Particularités |
|---|---|---|
| `dev` | base, mise, guard, podman, ssh · agent | sudo, groupe podman, outils courants (gh, node, python, uv, jq, rg, fd, yq, gitleaks, lefthook, docker-compose, chezmoi) |
| `agent-sandbox` | base, mise, guard, podman, ssh · agent | ni sudo ni groupe podman, `automount` et `interop` coupés |

## Questions ouvertes

- `ws-creator diff <machine>` à partir de la provenance, comme `copier update`.
- Fragments apportés par un catalogue perso.
- `AGENTS.md` du modèle `dev`.

## Plan

1. `templates/` (`dev`, `agent-sandbox`), clé `Description`, retrait d'`examples/`.
2. Sources (chemins locaux, dépôts git en cache), `list` en trois sections avec la source réelle.
3. `init` : valeurs, réécriture, provenance, validation, aperçu.
4. Tests Pester des modèles et d'`init`.
5. Aide `Get-Help`, README, 0.2.0.
