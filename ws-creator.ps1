#Requires -Version 7.0
# ws-creator depuis un clone du dépôt, sans l'installer : .\ws-creator.ps1 new <machine> [-Apply]
# Installé (Install-PSResource WsCreator), la même commande s'appelle ws-creator.
$ErrorActionPreference = 'Stop'
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'src\WsCreator') -Force
Invoke-WsCreator @args
