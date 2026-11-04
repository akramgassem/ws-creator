@{
    RootModule           = 'WsCreator.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = '2fda313d-cda1-456b-b521-ef744cd681f0'
    Author               = 'Akram Gassem'
    Copyright            = '(c) 2026 Akram Gassem. MIT License.'
    Description          = 'Environnements WSL décrits par des dossiers : cloud-init, puis quelques scripts. Créer, rejouer, purger une machine depuis Windows.'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')
    FunctionsToExport    = @(
        'Invoke-WsCreator',
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
