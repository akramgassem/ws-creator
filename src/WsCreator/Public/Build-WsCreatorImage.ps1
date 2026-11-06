function Build-WsCreatorImage {
    <#
    .SYNOPSIS
    Base image: fresh distro + the base and mise fragments (and user-data.yaml), exported to
    <WS_CREATOR_IMAGES>\<name>.tar; new imports it afterwards. No key, token, sshd or service.
    .PARAMETER Name
    The machine: folder <WS_CREATOR_MACHINES>\<Name>\, and the distro of the same name.
    .PARAMETER Apply
    Do it. Without it, only shows the steps (dry run).
    .EXAMPLE
    ws-creator image my-machine -Apply
    .LINK
    https://github.com/akramgassem/ws-creator
    #>
    param([Parameter(Mandatory)][string]$Name, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    $tmp = $m.Clone()
    $tmp.Name = "$($m.Name)-image"
    if (Test-Distro $tmp.Name) { throw "Distribution '$($tmp.Name)' already exists (previous build?), unregister it first" }
    $build = Join-Path -Path (Get-ImagesDir) -ChildPath "build\$($tmp.Name)"
    $image = Join-Path -Path (Get-ImagesDir) -ChildPath "$($m.Name).tar"

    Invoke-Step "wsl --install $($m.BaseDistribution) --name $($tmp.Name) --location $build --no-launch" {
        wsl --install $m.BaseDistribution --name $tmp.Name --location $build --no-launch
    }
    $fragments = @($m.CloudConfig | Where-Object { $_ -in 'base', 'mise' })
    Invoke-Step "cloud-init in $($tmp.Name): $($fragments -join ', ') + user-data.yaml" { Invoke-CloudInit $tmp $fragments }
    Invoke-Step "stop + wsl --export $($tmp.Name) $image" {
        Stop-Distro $tmp
        New-Item -ItemType Directory -Force -Path (Get-ImagesDir) | Out-Null
        wsl --export $tmp.Name $image
    }
    Invoke-Step "wsl --unregister $($tmp.Name)" {
        wsl --unregister $tmp.Name
        if (Test-Path -Path $build) { Remove-Item -Recurse -Force -Path $build }
    }
}
