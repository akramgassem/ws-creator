function Invoke-WsCreator {
    <#
    .SYNOPSIS
    La commande ws-creator (alias) : une sous-commande = une fonction du module
    (Get-Help New-WsCreatorMachine, Get-Help Update-WsCreatorMachine…).
    .EXAMPLE
    ws-creator new agent-sandbox -Apply
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('new', 'apply', 'list', 'status', 'code', 'stop', 'purge', 'image', 'doctor')]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Machine,    # dossier <WS_CREATOR_MACHINES>\<nom>

        [string[]]$Only,     # ex. -Only mise,ssh : seulement ces fragments ou modules
        [switch]$Apply,      # sans lui, aperçu
        [switch]$Force       # purge malgré du travail non poussé
    )
    $timer = [Diagnostics.Stopwatch]::StartNew()

    switch ($Command) {
        'new' { New-WsCreatorMachine -Name $Machine -Apply:$Apply }
        'apply' { Update-WsCreatorMachine -Name $Machine -Only $Only -Apply:$Apply }
        'purge' { if ($Only) { throw 'purge has no -Only: purge the machine, then new' }
                  Remove-WsCreatorMachine -Name $Machine -Apply:$Apply -Force:$Force }
        'stop' { Stop-WsCreatorMachine -Name $Machine -Apply:$Apply }
        'status' { Get-WsCreatorStatus -Name $Machine }
        'code' { Open-WsCreatorCode -Name $Machine }
        'image' { Build-WsCreatorImage -Name $Machine -Apply:$Apply }
        'list' { Get-WsCreatorMachineList }
        'doctor' { Test-WsCreatorHost }
    }

    if ($Apply -and $Command -in 'new', 'apply', 'image') {
        Write-Host ('Durée : {0:mm\:ss}' -f $timer.Elapsed)
    }
}
