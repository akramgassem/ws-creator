# Sourcé par les contrôles : configuration de la machine et fonctions communes.
# /etc/ws-creator/guard.conf : NO_AI_ATTRIBUTION, DENYLIST_EXCLUDE (machines/<nom>/files/ de ws-creator)
NO_AI_ATTRIBUTION=false
DENYLIST_EXCLUDE=""
[ -r /etc/ws-creator/guard.conf ] && . /etc/ws-creator/guard.conf
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

fail() { echo "ws-creator guard : $*" >&2; }

# <owner>/<repo> d'une URL GitHub (vide sinon)
github_slug() {
    case "$1" in
        *github.com[:/]*) local s=${1#*github.com[:/]}; s=${s%/}; echo "${s%.git}" ;;
    esac
}

# Les noms interdits s'appliquent-ils à ce dépôt ? Non si origin correspond à un motif
# DENYLIST_EXCLUDE (ex. « owner/* » : les dépôts du client lui-même).
denylist_applies() {
    [ -s /etc/ws-creator/denylist.sha256 ] || return 1
    local slug pattern patterns
    slug=$(github_slug "$(git remote get-url origin 2>/dev/null)")
    read -ra patterns <<< "$DENYLIST_EXCLUDE"   # sans expansion des * sur le disque
    for pattern in "${patterns[@]}"; do
        # shellcheck disable=SC2053
        [[ -n $slug && $slug == $pattern ]] && return 1
    done
    return 0
}

# texte sur l'entrée standard ; $1 : ce qui est contrôlé (pour le message)
denylist_check() { python3 -I "$here/denylist.py" "$1"; }
