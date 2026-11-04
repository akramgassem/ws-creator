# Préfixé à chaque module (et purge) par ws-creator : fonctions communes.
set -euo pipefail

# dossier personnel de l'utilisateur de la machine (vide tant qu'il n'existe pas)
user_home() { getent passwd "$WS_CREATOR_USER" | cut -d: -f6; }

# commande en tant que l'utilisateur de la machine : -H, jamais -i (voir README)
as_user() { sudo -u "$WS_CREATOR_USER" -H "$@"; }
