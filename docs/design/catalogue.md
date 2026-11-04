# Design : catalogue de modèles et `ws-creator init`

Statut : proposé · cible : 0.2.0

## Contexte

Aujourd'hui, une machine est un dossier que l'utilisateur écrit à la main dans
`WS_CREATOR_MACHINES` : il copie `examples/agent-sandbox` (qui n'est pas dans le module installé,
il faut le télécharger depuis GitHub), puis corrige l'utilisateur, la clé SSH, le port, le
sous-réseau et `Location`. Les erreurs ne se voient qu'à `new`, quand `Get-Machine` refuse.

On veut un catalogue de modèles, public et personnel, et une commande qui en tire une machine
prête à construire, que l'utilisateur s'approprie ensuite.

## Objectifs

- Un catalogue public livré avec le module : `dev` et `agent-sandbox`.
- Un catalogue personnel, au même format, que chacun range où il veut (dossier, dépôt privé).
- `ws-creator init <modèle> <nom>` : une machine valide sans rien corriger à la main.
- La machine créée appartient à l'utilisateur : il la modifie librement, ws-creator ne l'écrase
  jamais.
- Ce qui est commun (fragments) continue de suivre les mises à jour du module.

## Hors du périmètre

- Un modèle « minimal » : une distro nue, c'est `wsl --install`.
- Mettre à jour une machine existante quand son modèle change (on prépare le terrain :
  provenance, ci-dessous).
- Des catalogues distants (URL git, registre OCI) : un clone local suffit pour commencer.

## Vocabulaire

| Terme | C'est | Appartient à | Mis à jour par |
|---|---|---|---|
| fragment | `cloud-config/<f>.yaml`, cité par son nom | module | `Update-PSResource WsCreator` |
| modèle | un dossier machine du catalogue | module ou utilisateur | le module, ou son auteur |
| machine | `WS_CREATOR_MACHINES\<nom>\`, créée par `init` | utilisateur | l'utilisateur seul |
| distro | la distro WSL construite par `new` / `apply` | utilisateur | `apply`, `purge` + `new` |

## Mécanisme

### Un modèle est une machine valide

Même format qu'une machine : `machine.psd1`, `user-data.yaml`, et ce qu'elle cite (`AGENTS.md`,
`files/`). Pas de syntaxe de modèle (`{{user}}`) : ws-creator reste sans moteur de modèles.
Le modèle porte un utilisateur, une clé, un port et un sous-réseau d'exemple ; `init` les
remplace. Une clé en plus dans `machine.psd1`, ignorée par `Get-Machine` :

```powershell
Description = 'Machine de travail : sudo, podman, garde-fous git'   # affichée par list
```

Conséquences :

- n'importe quelle machine devient un modèle par simple copie dans un catalogue ;
- chaque modèle se teste comme une machine (`Get-Machine` dans les tests Pester) ;
- `examples/` disparaît : les modèles du module le remplacent.

### Catalogues et résolution

| Source | Emplacement | Ordre |
|---|---|---|
| perso | `WS_CREATOR_TEMPLATES` : un ou plusieurs dossiers séparés par `;` | lus d'abord, dans l'ordre |
| module | `src/WsCreator/templates/` | en dernier |

Un nom trouvé dans plusieurs sources : le premier gagne (comme `PATH`), `list` signale le modèle
masqué. On peut donc redéfinir `dev` à sa façon.

### `ws-creator init <modèle> <nom>`

1. Résout le modèle ; refuse si `WS_CREATOR_MACHINES\<nom>\` existe déjà.
2. Copie le dossier du modèle dans un dossier temporaire.
3. Calcule les valeurs d'identité (paramètres pour forcer chacune) :

   | Valeur | Par défaut | Paramètre |
   |---|---|---|
   | nom, `hostname` | `<nom>` | — |
   | utilisateur | `$env:USERNAME` en minuscules, réduit à `[a-z0-9_-]`, commence par une lettre | `-User` |
   | clé SSH | `~\.ssh\id_ed25519.pub` (sinon : erreur avec la commande `ssh-keygen`) | `-PublicKey` |
   | port SSH | le premier libre à partir de 2222 : ni dans une autre machine, ni en écoute sous Windows | `-Port` |
   | sous-réseau podman | le premier `10.89.N.0/24` libre parmi les machines | `-Subnet` |
   | `Location` | `WS_CREATOR_LOCATION`, sinon `C:\WSL` | `-Location` |

4. Réécrit ces valeurs, et seulement elles, aux emplacements que `Get-Machine` vérifie déjà :
   - `machine.psd1` : `Location`, `Ssh.Port`, `Ssh.PublicKey`, `PodmanSubnet` ;
   - `user-data.yaml` : `- name: <u>`, `default=<u>`, `hostname=<nom>`, `AllowUsers <u>`,
     `Port <p>`, `default_subnet = "<s>"`, les entrées de `ssh_authorized_keys`,
     `/home/<u>/` et `owner: <u>:<u>`.

   Les remplacements sont ancrés sur ces motifs (pas de remplacement global du nom
   d'utilisateur : `dev` ne doit pas devenir `alice` dans `devcontainer`). Une ligne qui
   contient encore l'ancien utilisateur après réécriture est signalée.
5. Ajoute la provenance dans `machine.psd1` :

   ```powershell
   Template        = 'dev'
   TemplateSource  = 'module'      # ou le dossier du catalogue perso
   TemplateVersion = '0.2.0'       # version du module, ou commit du catalogue perso s'il est en git
   ```

6. Valide le résultat avec `Get-Machine` et `Test-MachineConflict` ; en cas d'échec, rien n'est
   écrit. Sinon, déplace le dossier dans `WS_CREATOR_MACHINES\<nom>\`.
7. Affiche la suite : relire `user-data.yaml`, puis `ws-creator new <nom> -Apply`.

Comme les autres commandes : sans `-Apply`, aperçu (valeurs calculées, fichiers écrits).

### `ws-creator list`

```
Modèles
  dev             module   Machine de travail : sudo, podman, garde-fous git
  agent-sandbox   module   Bac à sable pour agent : ni sudo, ni disque Windows
  panda           perso    C:\…\ws-templates
Machines (C:\Dev\ws-machines)
  agent-sandbox   agent-sandbox@0.1.0
  panda-machine   —
Distros WSL
  …
```

## S'approprier sa machine

Après `init`, le dossier est à l'utilisateur, comme un projet sorti de `dotnet new` :

- `user-data.yaml` : paquets, outils mise, `sudo`, `wsl.conf` (disque Windows, interop) ;
- `machine.psd1` : fragments (`podman` en moins…), modules, `AgentInstructions` ;
- `AGENTS.md`, `files/`.

Il rejoue avec `ws-creator apply <nom> -Apply`, ou repart de zéro avec `purge` puis `new`.
Il versionne son dossier de machines où il veut (dépôt privé recommandé : clés publiques,
noms d'utilisateur, motifs des garde-fous).

Ce qui suit le module : les fragments, `files/`, `modules/` (`Update-PSResource WsCreator`).
Ce qui ne bouge plus : la copie faite par `init`. D'où la règle pour les modèles : y mettre le
moins possible, et déplacer dans un fragment ce qui sert à plusieurs modèles.

## Modèles du module

| Modèle | Fragments, modules | Différences |
|---|---|---|
| `dev` | base, mise, guard, podman, ssh · agent | sudo, groupe podman, outils de travail courants (gh, node, python, uv, jq, rg, fd, yq, gitleaks, lefthook, docker-compose), chezmoi pour les dotfiles |
| `agent-sandbox` | base, mise, guard, podman, ssh · agent | ni sudo ni groupe podman, `automount` et `interop` coupés, outils réduits |

`dev` vient de panda-machine sans ce qui est personnel (paquets Rust/psql, aws-cli, duckdb,
act, Angular), à trancher dans la PR.

## Alternatives écartées

- **Héritage (« cette machine est `dev` plus mes ajouts », comme `FROM` d'un Dockerfile).**
  cloud-init additionne les listes : l'utilisateur serait déclaré deux fois ; WSL ne lit qu'un
  `/etc/wsl.conf`, qu'il faudrait fusionner. Il faudrait un moteur de modèles ou une fusion YAML
  propre à ws-creator. La copie + les fragments par nom donnent le même partage, sans ça.
- **Descripteur (`template.psd1` qui génère les fichiers).** Plus guidé, mais un schéma à
  maintenir, et un modèle perso ne peut exprimer que ce que le schéma prévoit.
- **Préfixe obligatoire (`perso/dev`).** Sans ambiguïté, mais plus long ; le masquage signalé
  par `list` suffit.

## Questions ouvertes

- `ws-creator diff <machine>` (plus tard) : comparer la machine à la version courante de son
  modèle, à la manière de `copier update`, grâce à la provenance.
- Un catalogue perso peut-il apporter ses propres fragments (`cloud-config/` à côté des
  modèles) ? Utile, mais change la résolution des fragments : à part.
- `AGENTS.md` du modèle `dev` : générique, ou absent ?

## Plan

1. `src/WsCreator/templates/` (`dev`, `agent-sandbox`), clé `Description`, `examples/` retiré.
2. Résolution des catalogues (`WS_CREATOR_TEMPLATES`, module) et `list` en trois sections.
3. `init` : calcul des valeurs, réécriture ancrée, provenance, validation, aperçu / `-Apply`.
4. Tests Pester : chaque modèle valide ; `init` sur un catalogue de test (réécriture, ports et
   sous-réseaux libres, refus si la machine existe, rien d'écrit en cas d'échec).
5. Aide `Get-Help` complète (prévue pour 0.1.1) ; README ; version 0.2.0.
