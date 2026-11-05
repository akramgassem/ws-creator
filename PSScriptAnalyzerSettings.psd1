# PowerShell lint: Invoke-ScriptAnalyzer -Path src -Recurse -Settings PSScriptAnalyzerSettings.psd1
@{
    ExcludeRules = @(
        # Write-Host is the CLI's display (dry run, steps), not data for the pipeline
        'PSAvoidUsingWriteHost'
        # ws-creator does the opposite of -WhatIf: dry run by default, -Apply to act (Invoke-Step)
        'PSUseShouldProcessForStateChangingFunctions'
        # the BOM only matters to Windows PowerShell 5.1; the module requires PowerShell 7
        'PSUseBOMForUnicodeEncodedFile'
    )
}
