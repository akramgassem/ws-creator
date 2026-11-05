function Test-WsCreatorHost {
    <#
    .SYNOPSIS
    Workstation check: WSL, network, Falcon, ssh, and for each machine: description, distro,
    conflicts, private key permissions.
    .EXAMPLE
    ws-creator doctor
    .LINK
    https://github.com/akramgassem/ws-creator
    #>
    function Show([string]$Mark, [string]$Text) { Write-Host "$Mark $Text" }

    $wslVersion = [regex]::Match((wsl --version | Select-Object -First 1), '\d+(\.\d+)+').Value
    Show 'ℹ' "WSL $wslVersion$(if ($wslVersion -like '2.6.*') { ': expected warning about the systemd user session (README)' })"

    $wslconfig = Get-Content -Path (Join-Path -Path $HOME -ChildPath '.wslconfig') -Raw -ErrorAction SilentlyContinue
    if ($wslconfig -match 'networkingMode\s*=\s*mirrored') {
        Show 'ℹ' 'WSL mirrored networking: ports and subnets are shared, unique per machine'
    }
    else { Show 'ℹ' 'WSL networking not mirrored: ws-creator was designed and tested with mirrored' }

    if (Get-Service -Name CSFalconService -ErrorAction SilentlyContinue) {
        Show 'ℹ' 'CrowdStrike Falcon present: podman as root, no systemd user session'
    }

    $sshConfig = Join-Path -Path $HOME -ChildPath '.ssh\config'
    if ((Get-Content -Path $sshConfig -Raw -ErrorAction SilentlyContinue) -match '(?m)^Include ws-creator/\*\.conf') {
        Show '✓' '~\.ssh\config includes ws-creator/*.conf'
    }
    else { Show '✗' '~\.ssh\config lacks "Include ws-creator/*.conf" (apply -Only ssh adds it)' }

    # OpenSSH accepts a private key only if readable by the user, SYSTEM and Administrators
    $allowed = @([Security.Principal.WindowsIdentity]::GetCurrent().User.Value, 'S-1-5-18', 'S-1-5-32-544')
    foreach ($name in Get-MachineName) {
        try { $m = Get-Machine $name }
        catch { Show '✗' "${name}: $($_.Exception.Message)"; continue }

        $state = Get-DistroState $m.Name
        Show 'ℹ' "$($m.Name): distro $(if ($state) { $state } else { 'missing' })$(if ($state) { ', disk ' + (Get-DiskSize $m) })"

        try { Test-MachineConflict $m; Show '✓' "$($m.Name): no SSH port or subnet conflict" }
        catch { Show '✗' "$($m.Name): $($_.Exception.Message)" }

        if ($m.Ssh) {
            $key = Join-Path -Path $HOME -ChildPath ".ssh\$($m.Ssh.PublicKey -replace '\.pub$', '')"
            $others = (Get-Acl -Path $key).Access | ForEach-Object {
                try { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } catch { $_.IdentityReference.Value }
            } | Where-Object { $_ -notin $allowed }
            if ($others) { Show '✗' "$($m.Name): private key $key readable by other accounts (icacls, see README)" }
            else { Show '✓' "$($m.Name): private key permissions OK" }
        }
    }
}
