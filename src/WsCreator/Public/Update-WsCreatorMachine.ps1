function Update-WsCreatorMachine {
    <#
    .SYNOPSIS
    Reapplies fragments and modules on an existing distro (-Only: just some of them).
    cloud-init adds and removes nothing: to remove a permission, purge, then new.
    .PARAMETER Name
    The machine: folder <WS_CREATOR_MACHINES>\<Name>\, and the distro of the same name.
    .PARAMETER Only
    Just these fragments or modules of the machine, e.g. -Only mise,agent.
    .PARAMETER Apply
    Do it. Without it, only shows the steps (dry run).
    .EXAMPLE
    ws-creator apply my-machine -Only guard,agent -Apply
    .LINK
    https://github.com/akramgassem/ws-creator
    #>
    param([Parameter(Mandatory)][string]$Name, [string[]]$Only, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    Test-MachineConflict $m
    if (-not (Test-Distro $m.Name)) { throw "Distribution '$($m.Name)' not found, run 'new' first" }
    Invoke-Machine $m $Only
}
