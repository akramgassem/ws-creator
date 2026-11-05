# init: the identity values of a new machine, and their rewriting in a copy of a template.

# Linux user name from the Windows one: lowercase, [a-z0-9_-] only
function ConvertTo-LinuxUser([string]$Name) {
    $user = ($Name.ToLowerInvariant() -replace '[^a-z0-9_-]', '')
    if ($user -notmatch '^[a-z_]') { $user = "u$user" }
    return $user
}

# Is a TCP port listening on Windows (mirrored networking: shared with every distro)?
function Test-WindowsPort([int]$Port) {
    [bool](Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue)
}

# Machines already described: their SSH ports and podman subnets
function Get-UsedMachineValue {
    $ports = @(); $subnets = @()
    foreach ($name in Get-MachineName) {
        $o = Import-PowerShellDataFile -Path (Join-Path -Path (Get-MachineDir $name) -ChildPath 'machine.psd1')
        if ($o.Ssh.Port) { $ports += [int]$o.Ssh.Port }
        if ($o.PodmanSubnet) { $subnets += $o.PodmanSubnet }
    }
    @{ Ports = $ports; Subnets = $subnets }
}

function Get-FreeSshPort {
    $used = (Get-UsedMachineValue).Ports
    for ($p = 2222; $p -lt 2400; $p++) {
        if ($p -notin $used -and -not (Test-WindowsPort $p)) { return $p }
    }
    throw 'No free SSH port between 2222 and 2399: pass -Port'
}

function Get-FreePodmanSubnet {
    $used = (Get-UsedMachineValue).Subnets
    for ($n = 1; $n -lt 256; $n++) {
        $subnet = "10.89.$n.0/24"
        if ($subnet -notin $used) { return $subnet }
    }
    throw 'No free subnet in 10.89.0.0/16: pass -Subnet'
}

# Rewrites the identity values in a copy of a template ($Dir), where Get-Machine checks them.
# $Values: Name, User, PublicKey (file name in ~\.ssh), Key (type and key), Port, Subnet,
# Location. Returns the lines that still hold the template's user, to be reported.
function Set-MachineIdentity([string]$Dir, [hashtable]$Values) {
    $psd1Path = Join-Path -Path $Dir -ChildPath 'machine.psd1'
    $userDataPath = Join-Path -Path $Dir -ChildPath 'user-data.yaml'
    $old = Import-PowerShellDataFile -Path $psd1Path
    $text = [IO.File]::ReadAllText($userDataPath)
    $oldUser = (Get-UserDataValue $text).User
    $u = $Values.User
    $esc = [regex]::Escape($oldUser)

    $text = $text -replace "(?m)^(\s*-\s*name:\s*)$esc(\s*)$", "`${1}$u`$2"
    $text = $text -replace '(?m)^(\s*default=)\S+', "`${1}$u"
    $text = $text -replace '(?m)^(\s*hostname=)\S+', "`${1}$($Values.Name)"
    $text = $text -replace "/home/$esc/", "/home/$u/"
    $text = $text -replace "(?m)^(\s*owner:\s*)${esc}:$esc(\s*)$", "`${1}${u}:$u`$2"
    if ($old.Ssh) {
        $text = $text -replace '(?m)^(\s*AllowUsers\s+)\S+', "`${1}$u"
        $text = $text -replace '(?m)^(\s*Port\s+)\d+(\s*)$', "`${1}$($Values.Port)`$2"
        $text = $text -replace '(?m)^(\s*-\s*)(ssh-[a-z0-9-]+|ecdsa-sha2-\S+)\s+\S+.*$', "`${1}$($Values.Key)"
    }
    if ($old.PodmanSubnet) {
        $text = $text -replace '(?m)^(\s*default_subnet\s*=\s*")[^"]*(")', "`${1}$($Values.Subnet)`$2"
    }
    [IO.File]::WriteAllText($userDataPath, $text)

    $psd1 = [IO.File]::ReadAllText($psd1Path)
    $psd1 = $psd1 -replace '(?m)^\s*Description\s*=.*\r?\n', ''
    $psd1 = $psd1 -replace "(?m)^(\s*Location\s*=\s*)'[^']*'", "`${1}'$($Values.Location)'"
    if ($old.Ssh) {
        $psd1 = $psd1 -replace '(Ssh\s*=\s*@\{[^}]*Port\s*=\s*)\d+', "`${1}$($Values.Port)"
        $psd1 = $psd1 -replace "(Ssh\s*=\s*@\{[^}]*PublicKey\s*=\s*)'[^']*'", "`${1}'$($Values.PublicKey)'"
    }
    if ($old.PodmanSubnet) {
        $psd1 = $psd1 -replace "(?m)^(\s*PodmanSubnet\s*=\s*)'[^']*'", "`${1}'$($Values.Subnet)'"
    }
    [IO.File]::WriteAllText($psd1Path, $psd1)

    if ($oldUser -eq $u) { return }
    foreach ($file in Get-ChildItem -Path $Dir -Recurse -File) {
        $n = 0
        foreach ($line in [IO.File]::ReadAllLines($file.FullName)) {
            $n++
            if ($line -match "\b$esc\b") { '{0}:{1}: {2}' -f [IO.Path]::GetRelativePath($Dir, $file.FullName), $n, $line.Trim() }
        }
    }
}

# Adds the provenance keys before the closing brace of machine.psd1, then the hash of the files
function Add-MachineProvenance([string]$Dir, $Template) {
    $psd1Path = Join-Path -Path $Dir -ChildPath 'machine.psd1'
    $lines = @(
        "    Template        = '$($Template.Name)'"
        "    TemplateSource  = '$($Template.Source)'"
    )
    if ($Template.Version) { $lines += "    TemplateVersion = '$($Template.Version)'" }
    $lines += "    TemplateHash    = '__HASH__'"
    $psd1 = [IO.File]::ReadAllText($psd1Path) -replace "`r", ''
    $close = $psd1.LastIndexOf('}')
    $psd1 = $psd1.Substring(0, $close).TrimEnd() + "`n`n    # copied by ws-creator init: list compares the files with TemplateHash`n" + ($lines -join "`n") + "`n}`n"
    [IO.File]::WriteAllText($psd1Path, $psd1)
    $psd1 = $psd1.Replace('__HASH__', (Get-MachineHash $Dir))
    [IO.File]::WriteAllText($psd1Path, $psd1)
}
