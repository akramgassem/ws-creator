function Update-WsCreatorMachine {
    <#
    .SYNOPSIS
    Reapplies fragments and modules on an existing distro (-Only: just some of them).
    cloud-init adds and removes nothing: to remove a permission, purge, then new.
    #>
    param([Parameter(Mandatory)][string]$Name, [string[]]$Only, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    Test-MachineConflict $m
    if (-not (Test-Distro $m.Name)) { throw "Distribution '$($m.Name)' not found, run 'new' first" }
    Invoke-Machine $m $Only
}
