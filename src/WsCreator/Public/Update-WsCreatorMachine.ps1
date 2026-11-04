function Update-WsCreatorMachine {
    <#
    .SYNOPSIS
    Rejoue fragments et scripts sur une distro existante (-Only : certains seulement).
    cloud-init ajoute et ne retire rien : pour retirer un droit, purge puis new.
    #>
    param([Parameter(Mandatory)][string]$Name, [string[]]$Only, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    Test-MachineConflict $m
    if (-not (Test-Distro $m.Name)) { throw "Distribution '$($m.Name)' not found, run 'new' first" }
    Invoke-Machine $m $Only
}
