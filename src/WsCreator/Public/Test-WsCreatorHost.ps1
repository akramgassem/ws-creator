function Test-WsCreatorHost {
    <#
    .SYNOPSIS
    Diagnostic du poste : WSL, réseau, Falcon, ssh, et pour chaque machine : description,
    distro, conflits, droits de la clé privée.
    #>
    function Show([string]$Mark, [string]$Text) { Write-Host "$Mark $Text" }

    $wslVersion = [regex]::Match((wsl --version | Select-Object -First 1), '\d+(\.\d+)+').Value
    Show 'ℹ' "WSL $wslVersion$(if ($wslVersion -like '2.6.*') { ' : avertissement « systemd user session » attendu (README)' })"

    $wslconfig = Get-Content -Path (Join-Path -Path $HOME -ChildPath '.wslconfig') -Raw -ErrorAction SilentlyContinue
    if ($wslconfig -match 'networkingMode\s*=\s*mirrored') {
        Show 'ℹ' 'réseau WSL mirrored : ports et sous-réseaux partagés, uniques par machine'
    }
    else { Show 'ℹ' 'réseau WSL non mirrored : ws-creator a été conçu et testé en mirrored' }

    if (Get-Service -Name CSFalconService -ErrorAction SilentlyContinue) {
        Show 'ℹ' 'CrowdStrike Falcon présent : podman en root, pas de session systemd utilisateur'
    }

    $sshConfig = Join-Path -Path $HOME -ChildPath '.ssh\config'
    if ((Get-Content -Path $sshConfig -Raw -ErrorAction SilentlyContinue) -match '(?m)^Include ws-creator/\*\.conf') {
        Show '✓' '~\.ssh\config inclut ws-creator/*.conf'
    }
    else { Show '✗' '~\.ssh\config sans « Include ws-creator/*.conf » (apply -Only ssh le pose)' }

    # OpenSSH n'accepte une clé privée lisible que par l'utilisateur, SYSTEM et Administrateurs
    $allowed = @([Security.Principal.WindowsIdentity]::GetCurrent().User.Value, 'S-1-5-18', 'S-1-5-32-544')
    foreach ($name in Get-MachineName) {
        try { $m = Get-Machine $name }
        catch { Show '✗' "$name : $($_.Exception.Message)"; continue }

        $state = Get-DistroState $m.Name
        Show 'ℹ' "$($m.Name) : distro $(if ($state) { $state } else { 'absente' })$(if ($state) { ', disque ' + (Get-DiskSize $m) })"

        try { Test-MachineConflict $m; Show '✓' "$($m.Name) : pas de conflit de port SSH ni de sous-réseau" }
        catch { Show '✗' "$($m.Name) : $($_.Exception.Message)" }

        if ($m.Ssh) {
            $key = Join-Path -Path $HOME -ChildPath ".ssh\$($m.Ssh.PublicKey -replace '\.pub$', '')"
            $others = (Get-Acl -Path $key).Access | ForEach-Object {
                try { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } catch { $_.IdentityReference.Value }
            } | Where-Object { $_ -notin $allowed }
            if ($others) { Show '✗' "$($m.Name) : clé privée $key lisible par d'autres comptes (icacls, voir README)" }
            else { Show '✓' "$($m.Name) : droits de la clé privée corrects" }
        }
    }
}
