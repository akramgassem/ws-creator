# ws-creator

Lanceur d'environnements WSL : un dossier décrit une machine, ws-creator la construit
(cloud-init, puis quelques scripts), la fait évoluer et l'efface.

    ws-creator new    <machine> [-Apply]                 crée la distro (depuis l'image si elle existe) et joue tout
    ws-creator apply  <machine> [-Only a,b] [-Apply]     rejoue fragments et scripts sur une distro existante
    ws-creator purge  <machine> [-Apply] [-Force]        efface la distro (puis new pour la refaire)
    ws-creator stop   <machine> [-Apply]                 arrête proprement (conteneurs puis distro)
    ws-creator image  <machine> [-Apply]                 construit l'image <machine>.tar (base + mise)
    ws-creator status <machine>                          distro, disque, cloud-init, conteneurs, gh
    ws-creator code   <machine>                          ouvre VS Code sur ~/src de la machine
    ws-creator doctor                                    WSL, réseau, Falcon, conflits, droits des clés
    ws-creator list                                      machines et distros

Sans `-Apply` : aperçu, rien n'est exécuté. `purge` demande en plus de taper
le nom de la machine, et refuse s'il reste du travail non poussé dans `~/src` ou `~/scratch`
(modifications non commitées, commits non poussés, stash) sauf `-Force`. `new`, `apply`
et `image` affichent leur durée.

Accès : `ssh <machine>` (alias écrit par ws-creator avec le fragment ssh), VS Code Remote-SSH ou l'app
Claude avec ce même hôte. La distro démarre à la connexion.

![Architecture de ws-creator](docs/architecture.svg)

## Installer

Prérequis : Windows 11, WSL 2 en mode réseau mirrored, PowerShell 7.4+.

```powershell
Install-PSResource WsCreator        # PowerShell Gallery (ou : Install-Module WsCreator)
ws-creator doctor
```

`ws-creator` est l'alias d'`Invoke-WsCreator` ; chaque sous-commande est aussi une fonction
(`Get-Command -Module WsCreator`, `Get-Help New-WsCreatorMachine`). Mise à jour :
`Update-PSResource WsCreator`. Depuis un clone, sans installer : `.\ws-creator.ps1 <commande>`.

## Démarrer

Le module contient l'outil, pas vos machines : `examples/` en donne une à copier.

| Quoi | Où, par défaut | Variable pour le changer |
|---|---|---|
| vos machines (config, à versionner dans un dépôt privé) | `%APPDATA%\ws-creator\machines` | `WS_CREATOR_MACHINES` |
| images de base (reconstructibles) | `%LOCALAPPDATA%\ws-creator\images` | `WS_CREATOR_IMAGES` |
| disques des distros | `Location` de chaque `machine.psd1` | — |

```powershell
$machines = "$env:APPDATA\ws-creator\machines"
New-Item -ItemType Directory -Force $machines | Out-Null
Invoke-WebRequest https://github.com/akramgassem/ws-creator/archive/refs/heads/main.zip -OutFile $env:TEMP\wsc.zip
Expand-Archive $env:TEMP\wsc.zip $env:TEMP\wsc -Force
Copy-Item -Recurse $env:TEMP\wsc\ws-creator-main\examples\agent-sandbox $machines
# dans la copie : la clé de ~\.ssh\id_ed25519.pub dans user-data.yaml, Location dans machine.psd1
ws-creator new agent-sandbox            # aperçu
ws-creator new agent-sandbox -Apply
```

## Structure

Trois choses, trois formats, aucun moteur de modèles. Le module se suffit : il livre ses
fragments, fichiers et scripts avec lui (chemins ci-dessous relatifs à `src/WsCreator/`).

| Dossier | Contient | Format |
|---|---|---|
| `<WS_CREATOR_MACHINES>/<nom>/` | **qui** : une machine (le nom du dossier est celui de la distro), hors du module ; modèle dans `examples/` | `machine.psd1`, `user-data.yaml`, `files/` |
| `cloud-config/` | **comment** : fragments communs, sans variable | cloud-config |
| `files/` | **quoi** : fichiers copiés tels quels, chemin = destination (`files/usr/local/bin/x` -> `/usr/local/bin/x`) | fichiers texte |
| `modules/` | ce que cloud-init n'exprime pas (agent) | bash |
| `Public/`, `Private/` | l'outil : une commande = une fonction de `Public/`, les briques dans `Private/` | module PowerShell |
| `tests/` (racine du dépôt) | tests du module | Pester |

## Une machine (`<WS_CREATOR_MACHINES>/<nom>/`)

- **`machine.psd1`** : le côté Windows seulement, et les valeurs qui doivent être uniques entre
  machines (ws-creator les contrôle).

  | Clé | Obligatoire | Rôle |
  |---|---|---|
  | `BaseDistribution` | oui | image WSL (`wsl --list --online`) |
  | `Location` | oui | dossier du disque virtuel (`<Location>\<nom>`) |
  | `CloudConfig` | oui | fragments de `cloud-config/`, dans l'ordre (`user-data.yaml` vient en dernier) |
  | `Modules` | non | scripts de `modules/`, joués après cloud-init, dans l'ordre |
  | `PodmanSubnet` | si `podman` | sous-réseau /24 des conteneurs, **unique par machine** |
  | `Ssh` | si `ssh` | `Port` (**unique par machine**), `PublicKey` (dans `~\.ssh`) : alias SSH Windows |
  | `AgentInstructions` | non | fichier de ce dossier (ex. `AGENTS.md`) -> `~/.claude/CLAUDE.md` (module agent) |

- **`user-data.yaml`** : du cloud-config en clair, propre à la machine : `users` (et donc les
  droits : groupe `sudo` et règle `sudo`, ou `sudo: null`), `/etc/wsl.conf` (hostname,
  utilisateur par défaut, disque Windows, interop), paquets en plus, config mise
  (`~/.config/mise/config.toml`, `defer: true`). ws-creator y lit l'utilisateur (`default=` de
  `wsl.conf`) et vérifie qu'il est dans `users`, et que `hostname=` est le nom du dossier.
  Avec les fragments `ssh` et `podman`, il porte aussi les valeurs uniques de la machine, que
  ws-creator vérifie contre `machine.psd1` : `Port` et `AllowUsers` (`/etc/ssh/sshd_config.d/60-ws-creator-machine.conf`),
  la clé de `Ssh.PublicKey` (`ssh_authorized_keys`, sans son commentaire), `default_subnet`
  (`/etc/containers/containers.conf.d/60-ws-creator-machine.conf`), et le groupe `podman` de
  l'utilisateur (accès au socket, donc droits root).
- **`files/`** : fichiers système propres à la machine, ex. `etc/ws-creator/guard.conf` et
  `etc/ws-creator/denylist.sha256` (ignorés par git). Jamais sous `/home` : le dossier serait créé
  en root avant l'utilisateur ; ce qui va chez l'utilisateur passe par `user-data.yaml`.
- Rien de personnel dans une machine : l'identité git et la config de l'utilisateur sont dans
  ses dotfiles (ci-dessous).

## Config personnelle : dotfiles (chezmoi)

L'identité git, la branche par défaut et `gh` comme fournisseur d'identifiants vivent dans un
dépôt de dotfiles géré par [chezmoi](https://www.chezmoi.io/) : ils suivent l'utilisateur sur
toutes ses machines (et dans Codespaces), ws-creator n'en sait rien. Sur une machine neuve :

    gh auth login
    chezmoi init --apply <compte>    # demande une fois le nom et l'e-mail git

chezmoi est un outil de la config mise de la machine. Le dépôt est privé : cloud-init ne peut pas
le cloner au démarrage (aucun identifiant), d'où ces deux commandes, que `machine-state` rappelle
tant qu'elles n'ont pas été lancées. Ce qui décrit la machine (son `AGENTS.md`, ses hooks) reste
dans ws-creator.

## Fragments et modules

| Nom | Forme | Fait |
|---|---|---|
| `base` | cloud-config | paquets de base, journald, linger |
| `mise` | cloud-config | mise et les outils de sa config, shims pour les shells non interactifs |
| `guard` | cloud-config | hooks git de la machine (`/etc/ws-creator/hooks`), droits de `machine-state`, `machine-leftovers`, `machine-crumbs`, `machine-prune-branch` |
| `podman` | cloud-config | podman en root, groupe système podman, socket ouvert au groupe, compatibilité Docker |
| `ssh` | cloud-config | sshd sur `127.0.0.1` seulement, sans mot de passe ; ws-creator écrit l'alias SSH Windows |
| `agent` | script | `~/.claude/CLAUDE.md`, skill `/menage`, hook `SessionStart` -> `machine-state`, règle `allow` de `machine-prune-branch`, `~/src`, `~/scratch` |

L'utilisateur de la machine est l'uid 1000 : les fragments communs le trouvent par
`getent passwd 1000`, sans le connaître.

Services (bases, émulateurs) : la machine n'en démarre aucun. Chaque projet les déclare dans
son `compose.yaml` et les lance lui-même (`docker compose up -d`, ou une tâche mise). En WSL
mirrored, un port publié par podman (`ports:`) n'est pas joignable depuis la machine : le
`compose.yaml` utilise `network_mode: host`, et le port se choisit dans la commande du service.

## Provisionnement par cloud-init

1. ws-creator copie `files/` puis `<WS_CREATOR_MACHINES>/<nom>/files/` dans la distro, et écrit `/etc/ws-creator-profile`.
2. Il dépose les fragments de `CloudConfig`, puis `user-data.yaml`, dans
   `/var/lib/ws-creator/cloud-config/`, les valide un par un (`cloud-init schema`), et les assemble
   (`cloud-init devel make-mime`) en seed NoCloud ; `meta-data` ne contient que l'`instance-id`.
   `merge_how: 'dict(recurse_array,no_replace)+list(append)'` additionne les listes
   (`packages`, `write_files`, `runcmd`) d'un fragment à l'autre.
3. `cloud-init clean --logs`, arrêt de la distro, `cloud-init status --wait`. Les lignes
   `WARNING`/`ERROR` du journal s'affichent, et tout statut autre que `done` arrête ws-creator.

- `files/etc/cloud/cloud.cfg.d/99_zz-ws-creator.cfg` limite les sources à NoCloud (pas de lecture de
  `%USERPROFILE%\.cloud-init` par `/mnt/c`) ; le marqueur `cloud-init.disabled`, posé par
  l'accueil d'Ubuntu, est retiré avant chaque passage.
- **cloud-init ajoute, il ne retire jamais** : un rejeu (`apply`) ne reprend pas un droit, ne
  retire ni paquet ni fichier. Pour cela : `purge` puis `new` (infrastructure immuable).
  `runcmd` repasse à chaque rejeu : ses commandes vérifient avant d'agir.

## Garde-fous (fragment guard)

Ils vivent dans git et dans des commandes, pas dans un agent : ils valent pour un humain,
Claude, Codex ou VS Code. Un agent n'a qu'un adaptateur mince (le hook `SessionStart` du
module agent appelle `machine-state`).

- `machine-state` (`files/usr/local/bin/`) : conteneurs, `gh`, branche et état local de chaque
  dépôt de `~/src` et `~/scratch`, et le nombre de miettes (`machine-crumbs --local --summary`).
- `machine-leftovers` (`files/usr/local/bin/`) : ce que la purge ferait perdre. Lignes `!`
  (modifications, stash, commits sur aucune branche distante) : code 1, `purge` refuse. Lignes
  `·` : `~/scratch` hors git, pour mémoire. `purge` et `status` lancent ce même script.
- `machine-crumbs` : ce qui encombre sans être perdu, laissé par les sessions. Lignes `~`, code 0
  (la purge ne les compte pas). Branches `[gone]`, worktrees disparus ou dans le scratchpad
  (`/tmp/claude-<uid>/<projet>/<session>/`) d'une session terminée, serveurs en écoute dont le
  dossier courant est supprimé, `~/scratch/<sujet>` dont le README se dit jetable et que rien n'a
  modifié depuis `CRUMBS_SCRATCH_DAYS` jours (7, `guard.conf`), conteneurs dont le projet compose
  a disparu. Sans `--local`, il ajoute les branches dont la PR est fusionnée (`gh`, une requête
  par branche) et les serveurs lancés par la session appelante. Une session est vivante si le
  processus de son `~/.claude/sessions/<pid>.json` tourne encore.
- `machine-prune-branch <dépôt> <branche>` : supprime la branche, locale et sur origin, si et
  seulement si sa PR est fusionnée, aucune n'est ouverte, et tous ses commits sont dans la PR
  (fusion squash comprise) ; jamais la principale ni une branche extraite dans un worktree.
  `--check` : le verdict seul. Le module agent l'autorise sans confirmation
  (`permissions.allow`) : une règle explicite passe avant le classifieur du mode auto, qui
  refuse `git branch -D` et `git push --delete`.
- Skill `/menage` (`files/usr/local/share/ws-creator/claude/skills/`, posée par le module agent) : lance
  `machine-crumbs`, ramasse ce qui est à la session ou à personne, demande avant un dossier de
  scratch ou un conteneur, ne touche pas à ce qui est à une autre session active, et finit par
  `machine-leftovers`. Pas de hook `Stop` : il se déclencherait à chaque tour.
- Hooks (`files/usr/local/lib/ws-creator/git-hooks/`) : `core.hooksPath` système -> `/etc/ws-creator/hooks`,
  chaque hook est un lien vers `dispatch`, qui lance le contrôle ws-creator puis `.git/hooks/<nom>` du
  dépôt. Un `core.hooksPath` propre au dépôt (husky) remplace ceux de la machine.
  Contournement : `git … --no-verify`.
  - Hooks déclarés dans un dépôt : ils doivent aller dans `.git/hooks`, que `dispatch` appelle.
    lefthook s'installe sinon dans le `core.hooksPath` de la machine : l'installer avec
    `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0="$(git rev-parse --path-format=absolute --git-common-dir)/hooks" lefthook install`,
    et `no_auto_install: true` dans `lefthook.yml` (sans quoi il tente de remplacer les hooks
    de la machine quand sa config change). pre-commit (le framework) refuse de s'installer
    quand `core.hooksPath` est posé.
  - `pre-commit` : `gitleaks` sur l'index, noms interdits dans les lignes ajoutées et les noms de fichiers.
  - `commit-msg` : attribution à une IA (si `NO_AI_ATTRIBUTION=true`), noms interdits.
  - `pre-push` : refuse une branche dont la PR GitHub est fusionnée (aucune PR ouverte). Sans `gh`
    ou sans réseau, laisse passer.
- Réglages : `<WS_CREATOR_MACHINES>/<nom>/files/etc/ws-creator/guard.conf` (`NO_AI_ATTRIBUTION`, `DENYLIST_EXCLUDE`,
  motifs `owner/repo`) ; sans lui, attribution permise et pas d'exclusion.
- Noms interdits : `<WS_CREATOR_MACHINES>/<nom>/files/etc/ws-creator/denylist.sha256` (privé),
  empreintes sha256 de mots ou paires de mots en minuscules, une par ligne, `#` pour commenter
  Empreinte d'un mot :
  `-join ([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('mot')) | % { $_.ToString('x2') })`.
  Ne s'applique pas aux dépôts dont `origin` correspond à `DENYLIST_EXCLUDE` (ex. `owner/*`).

## Contrat des modules (scripts)

- `modules/<m>.sh` s'exécute en root dans la distro, reçoit les valeurs de `machine.psd1` via
  des variables `WS_CREATOR_*` (vérifiées en tête avec `: "${VAR:?}"`), dont `WS_CREATOR_USER`.
- `modules/lib.sh` est préfixé à chaque module : `user_home`, `as_user`. Les numéros
  de ligne d'une erreur bash incluent donc ceux de lib.sh.
- Un module est rejouable : `apply` peut le relancer sans dégât. Ce que la machine fournit
  (`AgentInstructions`, clé autorisée) est réécrit à chaque passage : `<WS_CREATOR_MACHINES>/<nom>/` fait foi.
- Agir en tant qu'utilisateur : `sudo -u "$WS_CREATOR_USER" -H`, jamais `-i`
  (`-i` passe par pam_systemd et provoque des erreurs systemd).
- Pas de secret dans `WS_CREATOR_*` : les variables sont visibles dans `ps`. Les secrets
  naissent dans la distro (`gh auth login`, `aws sso login`) et meurent avec elle.
- `/etc/ws-creator-profile` marque une distro créée par ws-creator ; `purge` refuse sans lui.

## Développer ws-creator

```powershell
Invoke-Pester -Path tests                                                    # Pester 5+
Invoke-ScriptAnalyzer -Path src -Recurse -Settings PSScriptAnalyzerSettings.psd1
```

Les tests couvrent ce qui ne touche pas à WSL : lecture et validation des machines, sélection `-Only` d'`apply`,
conflits, config SSH, et les règles de structure (pas de Jinja, fins de ligne Linux dans
`files/`, rien sous `/home`), et la machine d'`examples/`. Le reste s'essaie sur une machine
jetable (`<WS_CREATOR_MACHINES>/<essai>/`, puis `wsl --unregister`).

## Règles d'usage

- **Arrêter par `ws-creator stop`, jamais par `wsl --terminate`** : les distros
  partagent la pile réseau de WSL, un conteneur tué laisse ses règles NAT actives.
  Si c'est arrivé : `wsl --shutdown` (arrête toutes les distros).
- **Ports et sous-réseaux uniques par machine** (`Ssh.Port`, `PodmanSubnet`, et les ports
  des services des projets) : en WSL mirrored, Windows et toutes les distros les partagent.
  Un port déjà pris côté Windows (ex. un Postgres local sur 5432) l'est aussi pour les machines. `new`/`apply` refusent un port SSH ou
  un sous-réseau en double ; deux projets qui lancent un service sur le même port, sur deux
  machines à la fois, entrent en conflit.
- **Image de base** (`image`) : distro neuve + fragments `base` et `mise` (et `user-data.yaml`),
  sans clé, jeton, sshd ni service. À reconstruire quand les paquets ou les outils changent
  beaucoup (cloud-init rattrape les écarts, mais plus lentement).
- **Après `purge`** : révoquer le jeton GitHub (Settings > Applications > GitHub CLI),
  sauf s'il a été créé avec `gh auth login --expiring`.
- **Le cloisonnement est celui de la machine, pas de l'app** : une session Claude
  garde ses connecteurs Windows (Chrome, etc.) ; les désactiver pour un agent.

## Problèmes connus

- WSL 2.6.1 : `Failed to start the systemd user session for '<user>'` à chaque
  connexion. Sous un EDR qui confine systemd (ci-dessous), la session utilisateur échoue
  réellement ; sans conséquence pour ws-creator, qui n'en dépend pas.
- Postes avec un EDR comme CrowdStrike Falcon (`ws-creator doctor` le détecte) : il peut
  placer systemd sous `/sys/fs/cgroup/sensor.falcon` (700, aucun contrôleur délégué). D'où
  les choix des fragments, qui marchent avec ou sans : pas de session systemd utilisateur
  (pas de linger, diffusion journald coupée), podman en root (socket `/run/podman/podman.sock`,
  groupe podman), `pids_limit = 0`, pas de `--memory`/`--cpus`. ws-creator ne touche pas à
  la config de l'EDR.
- WSL mirrored : la redirection iptables de podman vers `127.0.0.1` n'aboutit pas (un port
  publié répond depuis Windows, pas depuis la distro) ; les services des projets passent par
  `network_mode: host`.
- `CONTAINER_HOST` et `DOCKER_HOST` sont dans `/etc/environment` (lu par PAM : ssh,
  VS Code ; pas par `wsl --exec`). `podman-docker` fournit `docker` et `/run/docker.sock`.
- `wsl -- <cmd>` fait réinterpréter la commande par bash : utiliser `--exec` dès
  qu'un argument contient | ' $ ou des espaces.
- PowerShell ajoute une fin de ligne (`\r\n`) à tout ce qu'il envoie dans l'entrée standard
  d'un programme : les modules passent par `tr -d '\r'`, la copie de `files/` retire aussi
  l'octet final.
- OpenSSH Windows exige des ACL privées : clé privée et `~\.ssh\ws-creator` accessibles
  seulement par l'utilisateur et SYSTEM.
- `ssh <machine> 'cmd'` sans `-t` : sortie en escalier dans la console Windows.
- `~/.bashrc` d'Ubuntu s'arrête tôt pour les shells non interactifs (`ssh 'cmd'`) :
  les shims mise sont ajoutés en tête, `mise activate` reste en fin de fichier.
- Depuis un clone, `pwsh -File ws-creator.ps1 … -Only a,b` passe `a,b` comme une seule valeur :
  lancer `.\ws-creator.ps1` depuis une session PowerShell, ou la commande `ws-creator` installée.

## Licence

[MIT](LICENSE)
