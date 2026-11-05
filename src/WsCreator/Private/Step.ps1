# Without -Apply, each step is only announced (dry run)
function Invoke-Step([string]$Description, [scriptblock]$Action) {
    if ($script:Apply) {
        Write-Host "-> $Description"
        & $Action
    }
    else {
        Write-Host "[Dry Run] $Description"
    }
}
