# Lint du code PowerShell : Invoke-ScriptAnalyzer -Path src -Recurse -Settings PSScriptAnalyzerSettings.psd1
@{
    ExcludeRules = @(
        # Write-Host est l'affichage de la CLI (aperçu, étapes), pas une donnée pour le pipeline
        'PSAvoidUsingWriteHost'
        # ws-creator fait l'inverse de -WhatIf : aperçu par défaut, -Apply pour agir (Invoke-Step)
        'PSUseShouldProcessForStateChangingFunctions'
        # le BOM ne sert qu'à Windows PowerShell 5.1 ; le module exige PowerShell 7
        'PSUseBOMForUnicodeEncodedFile'
    )
}
