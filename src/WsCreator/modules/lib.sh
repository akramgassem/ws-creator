# Prepended by ws-creator to every module (and purge): shared functions.
set -euo pipefail

# home folder of the machine's user (empty until it exists)
user_home() { getent passwd "$WS_CREATOR_USER" | cut -d: -f6; }

# command as the machine's user: -H, never -i (see README)
as_user() { sudo -u "$WS_CREATOR_USER" -H "$@"; }
