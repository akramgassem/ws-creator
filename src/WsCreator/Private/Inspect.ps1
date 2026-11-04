# Ce que la purge ferait perdre : files\usr\local\bin\machine-leftovers (le script que la
# machine a aussi dans son PATH), lancé depuis le dépôt, fragment guard ou non.
# Lignes « ! » : travail non poussé ; lignes « · » : ~/scratch hors git, pour mémoire.
function Get-UnsavedWork($m) {
    $PSNativeCommandUseErrorActionPreference = $false
    Get-Content -Path (Join-Path -Path $script:Root -ChildPath 'files\usr\local\bin\machine-leftovers') -Raw |
        wsl -d $m.Name -u $m.User --exec bash -c "tr -d '\r' | bash -s" 2>$null |
        Where-Object { $_ }
    $global:LASTEXITCODE = 0   # code 1 = travail non poussé, pas une erreur de ws-creator
}

$script:StatusScript = @'
home=$(getent passwd "$WS_CREATOR_USER" | cut -d: -f6)
printf 'Hôte        : %s (%s)\n' "$(hostname)" "$(. /etc/os-release; echo "$PRETTY_NAME")"
printf 'Disque /    : %s utilisés\n' "$(df -h --output=used / | tail -n1 | tr -d ' ')"
printf 'cloud-init  : %s\n' "$(cloud-init status 2>/dev/null | sed -n 's/^status: //p')"
printf 'sshd        : %s\n' "$(systemctl is-active ssh 2>/dev/null || true)"
if command -v podman >/dev/null; then
    printf 'Conteneurs  : %s\n' "$(podman ps --format '{{.Names}}' | paste -sd ' ' | sed 's/^$/aucun/')"
fi
gh="$home/.local/share/mise/shims/gh"
if [ -x "$gh" ]; then
    if sudo -u "$WS_CREATOR_USER" -H "$gh" auth status --hostname github.com >/dev/null 2>&1; then gs=connecté; else gs="non connecté"; fi
    printf 'GitHub (gh) : %s\n' "$gs"
fi
'@
