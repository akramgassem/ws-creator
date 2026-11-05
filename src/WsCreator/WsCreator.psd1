@{
    RootModule           = 'WsCreator.psm1'
    ModuleVersion        = '0.2.0'
    GUID                 = '2fda313d-cda1-456b-b521-ef744cd681f0'
    Author               = 'Akram Gassem'
    Copyright            = '(c) 2026 Akram Gassem. MIT License.'
    Description          = 'WSL environments described by folders: cloud-init, then a few scripts. Create, reapply and purge a machine from Windows.'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')
    FunctionsToExport    = @(
        'Invoke-WsCreator', 'Initialize-WsCreatorMachine',
        'New-WsCreatorMachine', 'Update-WsCreatorMachine', 'Remove-WsCreatorMachine', 'Stop-WsCreatorMachine',
        'Get-WsCreatorStatus', 'Get-WsCreatorMachineList', 'Open-WsCreatorCode', 'Build-WsCreatorImage', 'Test-WsCreatorHost'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @('ws-creator')
    PrivateData          = @{
        PSData = @{
            Tags       = @('WSL', 'cloud-init', 'Windows', 'devenv', 'podman', 'Linux')
            LicenseUri = 'https://github.com/akramgassem/ws-creator/blob/main/LICENSE'
            ProjectUri = 'https://github.com/akramgassem/ws-creator'
        }
    }
}
