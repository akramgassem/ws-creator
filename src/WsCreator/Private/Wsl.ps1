# Command as root in the distro; piped input goes to its stdin
function Invoke-Root($m, [string]$Command) {
    $input | wsl -d $m.Name -u root --exec sh -c $Command
}

# Running, Stopped, or $null if the distro does not exist
function Get-DistroState([string]$Name) {
    foreach ($line in wsl --list --verbose) {
        if ($line -match "^\*?\s*$([regex]::Escape($Name))\s+(\S+)\s+\d") { return $Matches[1] }
    }
}

function Test-Distro([string]$Name) { (wsl --list --quiet) -contains $Name }

function Get-DiskSize($m) {
    $vhdx = Get-ChildItem -Path (Join-Path -Path $m.Location -ChildPath $m.Name) -Filter *.vhdx -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($vhdx) { '{0:N1} GB' -f ($vhdx.Length / 1GB) }
}

# /etc/ws-creator-profile marks a distro created by ws-creator: purge refuses without it
function Test-WsCreatorDistro($m) {
    $PSNativeCommandUseErrorActionPreference = $false
    $owner = wsl -d $m.Name -u root --exec cat /etc/ws-creator-profile 2>$null
    return ($LASTEXITCODE -eq 0) -and ($owner -eq $m.Name)
}

# In WSL, all distros share one network stack: a container killed by "wsl --terminate"
# leaves its NAT rules (netavark) active. So containers are stopped cleanly first.
function Stop-Distro($m) {
    wsl -d $m.Name -u root --exec bash -c 'systemctl stop "ws-creator-*.service" 2>/dev/null; command -v podman >/dev/null && podman stop --all --time 10 >/dev/null 2>&1; true'
    wsl --terminate $m.Name
}
