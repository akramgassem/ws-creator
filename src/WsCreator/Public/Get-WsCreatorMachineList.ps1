function Get-WsCreatorMachineList {
    <#
    .SYNOPSIS
    Machines décrites (<WS_CREATOR_MACHINES>\) et distros WSL.
    #>
    Write-Host "Machines décrites dans $script:MachinesDir :"
    Get-MachineName
    wsl --list --verbose
}
