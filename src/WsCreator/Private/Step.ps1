# Sans -Apply, chaque étape est seulement annoncée (aperçu)
function Invoke-Step([string]$Description, [scriptblock]$Action) {
    if ($script:Apply) {
        Write-Host "-> $Description"
        & $Action
    }
    else {
        Write-Host "[Dry Run] $Description"
    }
}
