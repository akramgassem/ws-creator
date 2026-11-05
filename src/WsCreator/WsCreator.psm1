# ws-creator module: WSL machines described by <WS_CREATOR_MACHINES>\<name>\. One command = one
# function in Public\; Private\ holds the building blocks (WSL, cloud-init seed, modules, Windows-side SSH).
# The module is self-contained: cloud-config\, files\ and modules\ ship with it (PowerShell Gallery).

# The caller's preferences do not apply to module functions: they are set here.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:WSL_UTF8 = '1'

$script:Root = $PSScriptRoot   # cloud-config\, files\, modules\
# what belongs to the user lives outside the module, in the usual Windows locations:
# config in %APPDATA% (described machines), rebuildable data in %LOCALAPPDATA% (images)
$script:MachinesDir = if ($env:WS_CREATOR_MACHINES) { $env:WS_CREATOR_MACHINES } else { Join-Path -Path $env:APPDATA -ChildPath 'ws-creator\machines' }
$script:ImagesDir = if ($env:WS_CREATOR_IMAGES) { $env:WS_CREATOR_IMAGES } else { Join-Path -Path $env:LOCALAPPDATA -ChildPath 'ws-creator\images' }
$script:SshDir = Join-Path -Path $HOME -ChildPath '.ssh'
$script:Apply = $false   # set by each command: without -Apply, dry run only

foreach ($dir in 'Private', 'Public') {
    foreach ($file in Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath $dir) -Filter *.ps1) {
        . $file.FullName
    }
}

Set-Alias -Name ws-creator -Value Invoke-WsCreator
Export-ModuleMember -Alias ws-creator -Function (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter *.ps1).BaseName
