function Get-WsCreatorMachineList {
    <#
    .SYNOPSIS
    Described machines (<WS_CREATOR_MACHINES>\) and WSL distros.
    #>
    Write-Host "Machines described in ${script:MachinesDir}:"
    Get-MachineName
    wsl --list --verbose
}
