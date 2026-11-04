function Stop-WsCreatorMachine {
    <#
    .SYNOPSIS
    Arrête proprement : conteneurs, puis distro (jamais wsl --terminate seul, voir README).
    #>
    param([Parameter(Mandatory)][string]$Name, [switch]$Apply)
    $script:Apply = $Apply.IsPresent
    $m = Get-Machine $Name
    Invoke-Step "stop containers + wsl --terminate $($m.Name)" { Stop-Distro $m }
}
