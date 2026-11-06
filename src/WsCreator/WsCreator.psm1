# ws-creator module: developer workspaces on WSL, described by <WS_CREATOR_MACHINES>\<name>\. One command = one
# function in Public\; Private\ holds the building blocks (WSL, cloud-init seed, modules, Windows-side SSH).
# The module is self-contained: cloud-config\, files\, modules\ and templates\ ship with it (PowerShell Gallery).

# The caller's preferences do not apply to module functions: they are set here.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$env:WSL_UTF8 = '1'

$script:Root = $PSScriptRoot   # cloud-config\, files\, modules\, templates\
# what belongs to the user lives outside the module, in the usual Windows locations:
# config in %APPDATA% (described machines), rebuildable data in %LOCALAPPDATA% (images).
# Resolved on each call (Get-MachinesDir, Get-ImagesDir), so setting WS_CREATOR_MACHINES or
# WS_CREATOR_IMAGES after the module is loaded takes effect; these two only override (tests).
$script:MachinesDir = $null
$script:ImagesDir = $null
$script:CatalogsDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'ws-creator\catalogs'   # clones of git catalogs
$script:SshDir = Join-Path -Path $HOME -ChildPath '.ssh'
$script:Apply = $false   # set by each command: without -Apply, dry run only

foreach ($dir in 'Private', 'Public') {
    foreach ($file in Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath $dir) -Filter *.ps1) {
        . $file.FullName
    }
}

Set-Alias -Name ws-creator -Value Invoke-WsCreator
Export-ModuleMember -Alias ws-creator -Function (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter *.ps1).BaseName
