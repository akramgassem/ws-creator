function Stop-WsCreatorMachine {
    <#
    .SYNOPSIS
    Stops cleanly: containers, then the distro (never wsl --terminate alone, see README).
    .PARAMETER Name
    The machine: folder <WS_CREATOR_MACHINES>\<Name>\, and the distro of the same name.
    .PARAMETER Apply
    Do it. Without it, only shows the steps (dry run).
    .EXAMPLE
    ws-creator stop my-machine -Apply
    .LINK
    https://github.com/akramgassem/ws-creator
    #>
    param([Parameter(Mandatory)][string]$Name, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    Invoke-Step "stop containers + wsl --terminate $($m.Name)" { Stop-Distro $m }
}
