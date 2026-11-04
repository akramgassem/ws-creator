# Commande en root dans la distro ; ce qui arrive par le tuyau passe sur son entrée standard
function Invoke-Root($m, [string]$Command) {
    $input | wsl -d $m.Name -u root --exec sh -c $Command
}

# Running, Stopped, ou $null si la distro n'existe pas
function Get-DistroState([string]$Name) {
    foreach ($line in wsl --list --verbose) {
        if ($line -match "^\*?\s*$([regex]::Escape($Name))\s+(\S+)\s+\d") { return $Matches[1] }
    }
}

function Test-Distro([string]$Name) { (wsl --list --quiet) -contains $Name }

function Get-DiskSize($m) {
    $vhdx = Get-ChildItem -Path (Join-Path -Path $m.Location -ChildPath $m.Name) -Filter *.vhdx -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($vhdx) { '{0:N1} Go' -f ($vhdx.Length / 1GB) }
}

# /etc/ws-creator-profile marque une distro créée par ws-creator : purge refuse sans lui
function Test-WsCreatorDistro($m) {
    $PSNativeCommandUseErrorActionPreference = $false
    $owner = wsl -d $m.Name -u root --exec cat /etc/ws-creator-profile 2>$null
    return ($LASTEXITCODE -eq 0) -and ($owner -eq $m.Name)
}

# En WSL, toutes les distros partagent la même pile réseau : un conteneur tué par
# « wsl --terminate » laisse ses règles NAT (netavark) actives. On arrête donc
# proprement les conteneurs avant.
function Stop-Distro($m) {
    wsl -d $m.Name -u root --exec bash -c 'systemctl stop "ws-creator-*.service" 2>/dev/null; command -v podman >/dev/null && podman stop --all --time 10 >/dev/null 2>&1; true'
    wsl --terminate $m.Name
}
