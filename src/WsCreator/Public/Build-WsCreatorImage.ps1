function Build-WsCreatorImage {
    <#
    .SYNOPSIS
    Image de base : distro neuve + fragments base et mise (et user-data.yaml), exportée en
    <WS_CREATOR_IMAGES>\<nom>.tar ; new l'importe ensuite. Ni clé, ni jeton, ni sshd, ni service.
    #>
    param([Parameter(Mandatory)][string]$Name, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    $tmp = $m.Clone()
    $tmp.Name = "$($m.Name)-image"
    if (Test-Distro $tmp.Name) { throw "Distribution '$($tmp.Name)' already exists (previous build?), unregister it first" }
    $build = Join-Path -Path $script:ImagesDir -ChildPath "build\$($tmp.Name)"
    $image = Join-Path -Path $script:ImagesDir -ChildPath "$($m.Name).tar"

    Invoke-Step "wsl --install $($m.BaseDistribution) --name $($tmp.Name) --location $build --no-launch" {
        wsl --install $m.BaseDistribution --name $tmp.Name --location $build --no-launch
    }
    $fragments = @($m.CloudConfig | Where-Object { $_ -in 'base', 'mise' })
    Invoke-Step "cloud-init in $($tmp.Name): $($fragments -join ', ') + user-data.yaml" { Invoke-CloudInit $tmp $fragments }
    Invoke-Step "stop + wsl --export $($tmp.Name) $image" {
        Stop-Distro $tmp
        New-Item -ItemType Directory -Force -Path $script:ImagesDir | Out-Null
        wsl --export $tmp.Name $image
    }
    Invoke-Step "wsl --unregister $($tmp.Name)" {
        wsl --unregister $tmp.Name
        if (Test-Path -Path $build) { Remove-Item -Recurse -Force -Path $build }
    }
}
