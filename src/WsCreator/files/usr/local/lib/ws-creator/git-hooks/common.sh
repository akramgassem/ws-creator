# Sourced by the checks: machine configuration and shared functions.
# /etc/ws-creator/guard.conf: NO_AI_ATTRIBUTION, DENYLIST_EXCLUDE (ws-creator machines/<name>/files/)
NO_AI_ATTRIBUTION=false
DENYLIST_EXCLUDE=""
[ -r /etc/ws-creator/guard.conf ] && . /etc/ws-creator/guard.conf
here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

fail() { echo "ws-creator guard: $*" >&2; }

# <owner>/<repo> from a GitHub URL (empty otherwise)
github_slug() {
    case "$1" in
        *github.com[:/]*) local s=${1#*github.com[:/]}; s=${s%/}; echo "${s%.git}" ;;
    esac
}

# Do the forbidden names apply to this repo? Not if origin matches a DENYLIST_EXCLUDE
# pattern (e.g. "owner/*": the client's own repos).
denylist_applies() {
    [ -s /etc/ws-creator/denylist.sha256 ] || return 1
    local slug pattern patterns
    slug=$(github_slug "$(git remote get-url origin 2>/dev/null)")
    read -ra patterns <<< "$DENYLIST_EXCLUDE"   # no expansion of * against the disk
    for pattern in "${patterns[@]}"; do
        # shellcheck disable=SC2053
        [[ -n $slug && $slug == $pattern ]] && return 1
    done
    return 0
}

# text on stdin; $1: what is being checked (for the message)
denylist_check() { python3 -I "$here/denylist.py" "$1"; }
