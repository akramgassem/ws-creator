# Module ws-creator : machines WSL décrites par <WS_CREATOR_MACHINES>\<nom>\. Une commande = une
# fonction de Public\ ; Private\ contient les briques (WSL, seed cloud-init, scripts, SSH côté Windows).
# Le module se suffit : cloud-config\, files\ et modules\ sont livrés avec lui (PowerShell Gallery).

# Les préférences de l'appelant ne s'appliquent pas aux fonctions d'un module : on les pose ici.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:WSL_UTF8 = '1'

$script:Root = $PSScriptRoot   # cloud-config\, files\, modules\
# ce qui est à l'utilisateur vit hors du module, aux emplacements Windows usuels :
# la config dans %APPDATA% (machines décrites), le reconstructible dans %LOCALAPPDATA% (images)
$script:MachinesDir = if ($env:WS_CREATOR_MACHINES) { $env:WS_CREATOR_MACHINES } else { Join-Path -Path $env:APPDATA -ChildPath 'ws-creator\machines' }
$script:ImagesDir = if ($env:WS_CREATOR_IMAGES) { $env:WS_CREATOR_IMAGES } else { Join-Path -Path $env:LOCALAPPDATA -ChildPath 'ws-creator\images' }
$script:SshDir = Join-Path -Path $HOME -ChildPath '.ssh'
$script:Apply = $false   # posé par chaque commande : sans -Apply, aperçu seulement

foreach ($dir in 'Private', 'Public') {
    foreach ($file in Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath $dir) -Filter *.ps1) {
        . $file.FullName
    }
}

Set-Alias -Name ws-creator -Value Invoke-WsCreator
Export-ModuleMember -Alias ws-creator -Function (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter *.ps1).BaseName
