function Remove-WsCreatorMachine {
    <#
    .SYNOPSIS
    Deletes the distro (confirmed by typing its name). No partial purge: cloud-init removes
    nothing, so purge, then recreate (immutable infrastructure).
    Refuses while unpushed work remains, unless -Force.
    #>
    param([Parameter(Mandatory)][string]$Name, [switch]$Apply, [switch]$Force)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    if (-not (Test-Distro $m.Name)) { throw "Distribution '$($m.Name)' not found" }
    if (-not (Test-WsCreatorDistro $m)) { throw "'$($m.Name)' was not created by ws-creator, refusing to purge" }

    $unsaved = @(Get-UnsavedWork $m)
    if ($unsaved) {
        Write-Warning "Lost with $($m.Name):"
        $unsaved | ForEach-Object { Write-Host "    $_" }
    }
    if ($unsaved -like '!*' -and -not $Force) {
        if ($Apply) { throw 'Purge refused: push or discard this work, or rerun with -Force' }
        Write-Host '[Dry Run] purge would be refused (-Force to override)'
    }

    $target = Join-Path -Path $m.Location -ChildPath $m.Name
    if ($Apply -and (Read-Host "Type '$($m.Name)' to confirm the destruction") -ne $m.Name) {
        throw 'Purge cancelled'
    }
    Invoke-Step "wsl --unregister $($m.Name) (REMOVED $target)" {
        wsl --unregister $m.Name
        if (Test-Path -Path $target) { Remove-Item -Recurse -Force -Path $target }
        Remove-SshHost $m
    }
    if ($Apply) { Write-Host 'If gh was logged in: revoke its token on GitHub (Settings > Applications), unless it was an --expiring token.' }
}
