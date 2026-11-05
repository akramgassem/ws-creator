function Get-WsCreatorStatus {
    <#
    .SYNOPSIS
    Distro, disk, image, cloud-init, sshd, containers, gh, unpushed work.
    #>
    param([Parameter(Mandatory)][string]$Name)
    $m = Get-Machine $Name
    $state = Get-DistroState $m.Name
    Write-Host "Distro      : $(if ($state) { $state } else { 'missing' })"
    if (-not $state) { return }
    Write-Host "vhdx disk   : $(Get-DiskSize $m)"
    $image = Join-Path -Path $script:ImagesDir -ChildPath "$($m.Name).tar"
    if (Test-Path -Path $image) { Write-Host "Image       : $image ($((Get-Item $image).LastWriteTime.ToString('yyyy-MM-dd')))" }
    if ($state -ne 'Running') { Write-Host '(starting the distro for the check)' }
    $script:StatusScript | wsl -d $m.Name -u root --exec env "WS_CREATOR_USER=$($m.User)" bash -c "tr -d '\r' | bash -s"
    $unsaved = @(Get-UnsavedWork $m)
    Write-Host "Unpushed    : $(if (-not ($unsaved -like '!*')) { 'nothing' })"
    $unsaved | ForEach-Object { Write-Host "    $_" }
}
