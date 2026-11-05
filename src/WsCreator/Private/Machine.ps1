# A machine = machines\<name>\: machine.psd1 (Windows side), user-data.yaml (the machine's
# cloud-config), files\ (system files specific to the machine), and what machine.psd1 refers to.

function Get-MachineDir([string]$Name) { Join-Path -Path $script:MachinesDir -ChildPath $Name }

function Get-MachineName {
    if (-not (Test-Path -Path $script:MachinesDir)) { return }
    Get-ChildItem -Path $script:MachinesDir -Directory |
        Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'machine.psd1') } |
        ForEach-Object { $_.Name }
}

# wsl.conf values written in user-data.yaml: ws-creator reads them for the Windows side (SSH
# alias, VS Code) and checks they match the rest, instead of generating them.
function Get-UserDataValue([string]$Text) {
    $values = @{}
    if ($Text -match '(?m)^\s*hostname=(\S+)') { $values.Hostname = $Matches[1] }
    if ($Text -match '(?m)^\s*default=(\S+)') { $values.User = $Matches[1] }
    $values.Users = @([regex]::Matches($Text, '(?m)^\s*-\s*name:\s*(\S+)') | ForEach-Object { $_.Groups[1].Value })
    return $values
}

# -Dir: a machine outside WS_CREATOR_MACHINES (a template, or the copy init is preparing)
function Get-Machine([string]$Name, [string]$Dir) {
    if (-not $Name) { throw 'Machine name missing (machines\<name>\)' }
    $dir = if ($Dir) { $Dir } else { Get-MachineDir $Name }
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
    # values unique across machines are in machine.psd1 (ws-creator checks them) and in
    # user-data.yaml (the machine applies them): they must match
    if ('ssh' -in $m.CloudConfig) {
        if (-not $m.Ssh) { throw "Machine '$Name': fragment ssh needs Ssh in machine.psd1" }
        if ($text -notmatch "(?m)^\s*Port\s+$($m.Ssh.Port)\s*$") {
            throw "Machine '$Name': user-data.yaml has no sshd 'Port $($m.Ssh.Port)' (machine.psd1 Ssh.Port)"
        }
        if ($text -notmatch "(?m)^\s*AllowUsers\s+$([regex]::Escape($m.User))\s*$") {
            throw "Machine '$Name': user-data.yaml has no sshd 'AllowUsers $($m.User)'"
        }
        $key = ((Get-Content -Path $pub -Raw).Trim() -split '\s+')[0..1] -join ' '   # type and key, without the comment
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

# Windows and all distros share the network stack (WSL mirrored): a duplicate SSH port or
# subnet silently breaks another machine.
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

# -Only: names of the machine's fragments or modules; without -Only, everything
function Select-MachinePart($m, [string[]]$Only) {
    foreach ($o in $Only) {
        if ($o -notin $m.CloudConfig -and $o -notin $m.Modules) { throw "'$o' is neither a fragment nor a module of machine '$($m.Name)'" }
    }
    @{
        CloudConfig = @($m.CloudConfig | Where-Object { -not $Only -or $_ -in $Only })
        Modules     = @($m.Modules | Where-Object { -not $Only -or $_ -in $Only })
    }
}
