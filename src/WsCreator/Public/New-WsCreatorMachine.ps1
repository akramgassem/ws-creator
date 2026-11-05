function New-WsCreatorMachine {
    <#
    .SYNOPSIS
    Creates the distro (from <WS_CREATOR_IMAGES>\<name>.tar if it exists) and applies fragments, then modules.
    #>
    param([Parameter(Mandatory)][string]$Name, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    Test-MachineConflict $m
    if (Test-Distro $m.Name) { throw "Distribution '$($m.Name)' already exists, purge it first" }

    $target = Join-Path -Path $m.Location -ChildPath $m.Name
    $image = Join-Path -Path $script:ImagesDir -ChildPath "$($m.Name).tar"
    if (Test-Path -Path $image) {
        $date = (Get-Item -Path $image).LastWriteTime.ToString('yyyy-MM-dd')
        Invoke-Step "wsl --import $($m.Name) from $image ($date)" {
            New-Item -ItemType Directory -Force -Path $target | Out-Null
            wsl --import $m.Name $target $image
        }
    }
    else {
        Invoke-Step "wsl --install $($m.BaseDistribution) --name $($m.Name) --location $target --no-launch" {
            wsl --install $m.BaseDistribution --name $m.Name --location $target --no-launch
        }
    }
    Invoke-Machine $m
}
