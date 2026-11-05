#Requires -Version 7.0
# ws-creator from a clone of the repo, without installing it: .\ws-creator.ps1 new <machine> [-Apply]
# Once installed (Install-PSResource WsCreator), the same command is called ws-creator.
$ErrorActionPreference = 'Stop'
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'src\WsCreator') -Force
Invoke-WsCreator @args
