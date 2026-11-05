function Initialize-WsCreatorMachine {
    <#
    .SYNOPSIS
    Creates a machine folder from a template, with your own user, SSH key, port and subnet.
    .DESCRIPTION
    Copies the template into <WS_CREATOR_MACHINES>\<Name>\, rewrites the identity values where
    ws-creator checks them (user, hostname, SSH port and key, podman subnet, Location), records
    where the copy comes from (Template, TemplateSource, TemplateVersion, TemplateHash), then
    validates the result. Nothing is written if validation fails. The machine is yours
    afterwards: edit it freely, then create the distro with 'ws-creator new <Name> -Apply'.
    Templates come from WS_CREATOR_TEMPLATES (local folders or git repos), then the module.
    .PARAMETER Template
    Template name, as shown by 'ws-creator list'.
    .PARAMETER Name
    Name of the new machine: folder, distro and hostname.
    .PARAMETER User
    Linux user. Default: the Windows user name in lowercase, reduced to [a-z0-9_-].
    .PARAMETER PublicKey
    Public key file in ~\.ssh. Default: id_ed25519.pub.
    .PARAMETER Port
    SSH port, unique per machine. Default: the first free one from 2222.
    .PARAMETER Subnet
    Podman subnet, unique per machine. Default: the first free 10.89.N.0/24.
    .PARAMETER Location
    Folder of the virtual disk. Default: WS_CREATOR_LOCATION, otherwise C:\WSL.
    .PARAMETER Apply
    Write the machine folder. Without it, only shows what would be written.
    .EXAMPLE
    ws-creator init dev my-machine
    Shows the values init would use.
    .EXAMPLE
    ws-creator init agent-sandbox sandbox -Port 2250 -Apply
    .LINK
    https://github.com/akramgassem/ws-creator/blob/main/docs/design/catalogue.md
    #>
    param(
        [Parameter(Mandatory)][string]$Template,
        [Parameter(Mandatory)][string]$Name,
        [string]$User,
        [string]$PublicKey = 'id_ed25519.pub',
        [int]$Port,
        [string]$Subnet,
        [string]$Location,
        [switch]$Apply
    )
    $script:Apply = $Apply.IsPresent
    if ($Name -notmatch '^[a-z0-9][a-z0-9-]{0,62}$') { throw "Machine name '$Name': lowercase letters, digits and '-' only (it is also the hostname)" }
    $target = Get-MachineDir $Name
    if (Test-Path -Path $target) { throw "Machine '$Name' already exists: $target" }
    if (Test-Distro $Name) { throw "A WSL distro named '$Name' already exists" }

    foreach ($source in Get-TemplateSource) { Update-TemplateCatalog $source }
    $t = Get-Template | Where-Object { $_.Name -eq $Template -and -not $_.Shadowed }
    if (-not $t) { throw "Template '$Template' not found (ws-creator list)" }
    $tm = Import-PowerShellDataFile -Path (Join-Path -Path $t.Dir -ChildPath 'machine.psd1')

    $pub = Join-Path -Path $script:SshDir -ChildPath $PublicKey
    if (-not (Test-Path -Path $pub)) { throw "Public key not found: ~\.ssh\$PublicKey (ssh-keygen -t ed25519, or -PublicKey)" }
    $values = @{
        Name      = $Name
        User      = if ($User) { $User } else { ConvertTo-LinuxUser $env:USERNAME }
        PublicKey = $PublicKey
        Key       = ((Get-Content -Path $pub -Raw).Trim() -split '\s+')[0..1] -join ' '
        Location  = if ($Location) { $Location } elseif ($env:WS_CREATOR_LOCATION) { $env:WS_CREATOR_LOCATION } else { 'C:\WSL' }
    }
    if ($values.User -notmatch '^[a-z_][a-z0-9_-]{0,31}$') { throw "User '$($values.User)' is not a valid Linux user name" }
    if ($tm.Ssh) { $values.Port = if ($Port) { $Port } else { Get-FreeSshPort } }
    if ($tm.PodmanSubnet) { $values.Subnet = if ($Subnet) { $Subnet } else { Get-FreePodmanSubnet } }

    $work = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "ws-creator-init-$([guid]::NewGuid().ToString('n'))"
    $copy = Join-Path -Path $work -ChildPath $Name
    try {
        New-Item -ItemType Directory -Force -Path $work | Out-Null
        Copy-Item -Recurse -Path $t.Dir -Destination $copy
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -Path (Join-Path -Path $copy -ChildPath '.git')
        $leftovers = @(Set-MachineIdentity $copy $values)
        Add-MachineProvenance $copy $t
        $m = Get-Machine $Name -Dir $copy
        Test-MachineConflict $m

        Write-Host "Template  : $($t.Name) ($($t.Source)$(if ($t.Version) { " @ $($t.Version)" }))"
        Write-Host "User      : $($values.User)"
        if ($values.Port) { Write-Host "SSH       : port $($values.Port), key ~\.ssh\$PublicKey" }
        if ($values.Subnet) { Write-Host "Podman    : $($values.Subnet)" }
        Write-Host "Disk      : $(Join-Path -Path $values.Location -ChildPath $Name)"
        foreach ($line in $leftovers) { Write-Warning "still holds the template's user, check it: $line" }

        Invoke-Step "write $target" {
            New-Item -ItemType Directory -Force -Path $script:MachinesDir | Out-Null
            Copy-Item -Recurse -Path $copy -Destination $target
        }
        if ($Apply) { Write-Host "Next: edit $target if needed, then ws-creator new $Name -Apply" }
    }
    finally {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -Path $work
    }
}
