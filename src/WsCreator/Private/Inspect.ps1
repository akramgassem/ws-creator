# What a purge would lose: files\usr\local\bin\machine-leftovers (the script the machine
# also has in its PATH), run from the repo, with or without the guard fragment.
# "!" lines: unpushed work; "·" lines: ~/scratch outside git, for the record.
function Get-UnsavedWork($m) {
    $PSNativeCommandUseErrorActionPreference = $false
    Get-Content -Path (Join-Path -Path $script:Root -ChildPath 'files\usr\local\bin\machine-leftovers') -Raw |
        wsl -d $m.Name -u $m.User --exec bash -c "tr -d '\r' | bash -s" 2>$null |
        Where-Object { $_ }
    $global:LASTEXITCODE = 0   # exit 1 = unpushed work, not a ws-creator error
}

$script:StatusScript = @'
home=$(getent passwd "$WS_CREATOR_USER" | cut -d: -f6)
printf 'Host        : %s (%s)\n' "$(hostname)" "$(. /etc/os-release; echo "$PRETTY_NAME")"
printf 'Disk /      : %s used\n' "$(df -h --output=used / | tail -n1 | tr -d ' ')"
printf 'cloud-init  : %s\n' "$(cloud-init status 2>/dev/null | sed -n 's/^status: //p')"
printf 'sshd        : %s\n' "$(systemctl is-active ssh 2>/dev/null || true)"
if command -v podman >/dev/null; then
    printf 'Containers  : %s\n' "$(podman ps --format '{{.Names}}' | paste -sd ' ' | sed 's/^$/none/')"
fi
gh="$home/.local/share/mise/shims/gh"
if [ -x "$gh" ]; then
    if sudo -u "$WS_CREATOR_USER" -H "$gh" auth status --hostname github.com >/dev/null 2>&1; then gs="logged in"; else gs="not logged in"; fi
    printf 'GitHub (gh) : %s\n' "$gs"
fi
'@
