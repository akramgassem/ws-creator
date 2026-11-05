@{
    RootModule           = 'WsCreator.psm1'
    ModuleVersion        = '0.2.1'
    GUID                 = '2fda313d-cda1-456b-b521-ef744cd681f0'
    Author               = 'Akram Gassem'
    Copyright            = '(c) 2026 Akram Gassem. MIT License.'
    Description          = 'Workspace creator for developers on Windows: WSL workspaces described by folders, built with cloud-init. Create, update and delete them from PowerShell.'
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
            Tags         = @('WSL', 'workspace', 'developer', 'cloud-init', 'Windows', 'devenv', 'podman', 'Linux')
            LicenseUri   = 'https://github.com/akramgassem/ws-creator/blob/main/LICENSE'
            ProjectUri   = 'https://akramgassem.github.io/ws-creator/'
            ReleaseNotes = 'https://github.com/akramgassem/ws-creator/blob/main/CHANGELOG.md'
        }
    }
}
