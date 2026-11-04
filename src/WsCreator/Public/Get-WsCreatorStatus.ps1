function Get-WsCreatorStatus {
    <#
    .SYNOPSIS
    Distro, disque, image, cloud-init, sshd, conteneurs, gh, travail non poussé.
    #>
    param([Parameter(Mandatory)][string]$Name)
    $m = Get-Machine $Name
    $state = Get-DistroState $m.Name
    Write-Host "Distro      : $(if ($state) { $state } else { 'absente' })"
    if (-not $state) { return }
    Write-Host "Disque vhdx : $(Get-DiskSize $m)"
    $image = Join-Path -Path $script:ImagesDir -ChildPath "$($m.Name).tar"
    if (Test-Path -Path $image) { Write-Host "Image       : $image ($((Get-Item $image).LastWriteTime.ToString('yyyy-MM-dd')))" }
    if ($state -ne 'Running') { Write-Host '(démarrage de la distro pour le contrôle)' }
    $script:StatusScript | wsl -d $m.Name -u root --exec env "WS_CREATOR_USER=$($m.User)" bash -c "tr -d '\r' | bash -s"
    $unsaved = @(Get-UnsavedWork $m)
    Write-Host "Non poussé  : $(if (-not ($unsaved -like '!*')) { 'rien' })"
    $unsaved | ForEach-Object { Write-Host "    $_" }
}
