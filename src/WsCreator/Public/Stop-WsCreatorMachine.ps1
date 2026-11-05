function Stop-WsCreatorMachine {
    <#
    .SYNOPSIS
    Stops cleanly: containers, then the distro (never wsl --terminate alone, see README).
    #>
    param([Parameter(Mandatory)][string]$Name, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    Invoke-Step "stop containers + wsl --terminate $($m.Name)" { Stop-Distro $m }
}
