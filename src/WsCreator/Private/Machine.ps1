# Une machine = machines\<nom>\ : machine.psd1 (côté Windows), user-data.yaml (cloud-config
# de la machine), files\ (fichiers système propres à la machine), et ce que machine.psd1 cite.

function Get-MachineDir([string]$Name) { Join-Path -Path $script:MachinesDir -ChildPath $Name }

function Get-MachineName {
    if (-not (Test-Path -Path $script:MachinesDir)) { return }
    Get-ChildItem -Path $script:MachinesDir -Directory |
        Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'machine.psd1') } |
        ForEach-Object { $_.Name }
}

# Valeurs de wsl.conf écrites dans user-data.yaml : ws-creator les lit pour le côté Windows (alias
# SSH, VS Code) et vérifie qu'elles concordent avec le reste, au lieu de les générer.
function Get-UserDataValue([string]$Text) {
    $values = @{}
    if ($Text -match '(?m)^\s*hostname=(\S+)') { $values.Hostname = $Matches[1] }
    if ($Text -match '(?m)^\s*default=(\S+)') { $values.User = $Matches[1] }
    $values.Users = @([regex]::Matches($Text, '(?m)^\s*-\s*name:\s*(\S+)') | ForEach-Object { $_.Groups[1].Value })
    return $values
}

function Get-Machine([string]$Name) {
    if (-not $Name) { throw 'Machine name missing (machines\<nom>\)' }
    $dir = Get-MachineDir $Name
    $psd1 = Join-Path -Path $dir -ChildPath 'machine.psd1'
    $userData = Join-Path -Path $dir -ChildPath 'user-data.yaml'
    foreach ($file in $psd1, $userData) {
        if (-not (Test-Path -Path $file)) { throw "Machine '$Name': $file not found" }
    }
    $m = Import-PowerShellDataFile -Path $psd1
    $m.Name = $Name
    $m.Dir = $dir
    $m.UserData = $userData

    foreach ($key in 'BaseDistribution', 'Location', 'CloudConfig') {
        if (-not $m.ContainsKey($key)) { throw "Machine '$Name': machine.psd1 is missing key '$key'" }
    }
    $m.Modules = @($m.Modules | Where-Object { $_ })
    foreach ($f in $m.CloudConfig) {
        if (-not (Test-Path -Path (Join-Path -Path $script:Root -ChildPath "cloud-config\$f.yaml"))) {
            throw "Machine '$Name': cloud-config\$f.yaml not found"
        }
    }
    foreach ($s in $m.Modules) {
        if (-not (Test-Path -Path (Join-Path -Path $script:Root -ChildPath "modules\$s.sh"))) {
            throw "Machine '$Name': modules\$s.sh not found"
        }
    }

    $text = Get-Content -Path $userData -Raw
    if ($text -notmatch '^#cloud-config') { throw "Machine '$Name': user-data.yaml must start with #cloud-config" }
    $v = Get-UserDataValue $text
    if ($v.Hostname -ne $Name) { throw "Machine '$Name': wsl.conf in user-data.yaml says hostname=$($v.Hostname)" }
    if (-not $v.User) { throw "Machine '$Name': wsl.conf in user-data.yaml has no [user] default=" }
    if ($v.User -notin $v.Users) { throw "Machine '$Name': default=$($v.User) is not in the users of user-data.yaml" }
    $m.User = $v.User
    if ('mise' -in $m.CloudConfig -and $text -notmatch '\.config/mise/config\.toml') {
        throw "Machine '$Name': fragment mise needs ~/.config/mise/config.toml in user-data.yaml"
    }

    if ($m.Ssh) {
        if (-not ($m.Ssh.Port -and $m.Ssh.PublicKey)) { throw "Machine '$Name': Ssh needs Port and PublicKey" }
        $pub = Join-Path -Path $script:SshDir -ChildPath $m.Ssh.PublicKey
        if (-not (Test-Path -Path $pub)) { throw "Machine '$Name': public key not found: ~\.ssh\$($m.Ssh.PublicKey)" }
    }
    # les valeurs uniques entre machines sont dans machine.psd1 (ws-creator les contrôle) et dans
    # user-data.yaml (la machine les applique) : elles doivent concorder
    if ('ssh' -in $m.CloudConfig) {
        if (-not $m.Ssh) { throw "Machine '$Name': fragment ssh needs Ssh in machine.psd1" }
        if ($text -notmatch "(?m)^\s*Port\s+$($m.Ssh.Port)\s*$") {
            throw "Machine '$Name': user-data.yaml has no sshd 'Port $($m.Ssh.Port)' (machine.psd1 Ssh.Port)"
        }
        if ($text -notmatch "(?m)^\s*AllowUsers\s+$([regex]::Escape($m.User))\s*$") {
            throw "Machine '$Name': user-data.yaml has no sshd 'AllowUsers $($m.User)'"
        }
        $key = ((Get-Content -Path $pub -Raw).Trim() -split '\s+')[0..1] -join ' '   # type et clé, sans commentaire
        if (-not $text.Contains($key)) {
            throw "Machine '$Name': ~\.ssh\$($m.Ssh.PublicKey) is not in ssh_authorized_keys of user-data.yaml"
        }
    }
    if ('podman' -in $m.CloudConfig -and $m.PodmanSubnet -and
        $text -notmatch "(?m)^\s*default_subnet\s*=\s*`"$([regex]::Escape($m.PodmanSubnet))`"") {
        throw "Machine '$Name': user-data.yaml has no podman default_subnet = `"$($m.PodmanSubnet)`" (machine.psd1 PodmanSubnet)"
    }
    if ($m.AgentInstructions -and -not (Test-Path -Path (Join-Path -Path $dir -ChildPath $m.AgentInstructions))) {
        throw "Machine '$Name': AgentInstructions file not found: $($m.AgentInstructions)"
    }
    return $m
}

# Windows et toutes les distros partagent la pile réseau (WSL mirrored) : un port SSH ou un
# sous-réseau en double casse une autre machine sans message.
function Test-MachineConflict($m) {
    foreach ($other in Get-MachineName | Where-Object { $_ -ne $m.Name }) {
        $o = Import-PowerShellDataFile -Path (Join-Path -Path (Get-MachineDir $other) -ChildPath 'machine.psd1')
        $o.Name = $other
        if ($m.Ssh -and $o.Ssh -and $m.Ssh.Port -eq $o.Ssh.Port) {
            throw "Machine '$($m.Name)': Ssh.Port $($m.Ssh.Port) already used by '$other'"
        }
        if ($m.PodmanSubnet -and $m.PodmanSubnet -eq $o.PodmanSubnet) {
            throw "Machine '$($m.Name)': PodmanSubnet $($m.PodmanSubnet) already used by '$other'"
        }
        if ('podman' -in $m.CloudConfig -and 'podman' -in $o.CloudConfig -and -not ($m.PodmanSubnet -and $o.PodmanSubnet)) {
            Write-Warning "'$($m.Name)' and '$other': podman without PodmanSubnet on both, they share the default subnet"
        }
    }
}

# -Only : noms de fragments ou de scripts de la machine ; sans -Only, tout
function Select-MachinePart($m, [string[]]$Only) {
    foreach ($o in $Only) {
        if ($o -notin $m.CloudConfig -and $o -notin $m.Modules) { throw "'$o' is neither a fragment nor a module of machine '$($m.Name)'" }
    }
    @{
        CloudConfig = @($m.CloudConfig | Where-Object { -not $Only -or $_ -in $Only })
        Modules     = @($m.Modules | Where-Object { -not $Only -or $_ -in $Only })
    }
}
