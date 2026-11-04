# Tests du module ws-creator (Pester 5+) : Invoke-Pester -Path tests
# Ce qui ne touche pas à WSL : lecture et validation des machines, sélection -Only, conflits,
# config SSH Windows, et les règles de structure du dépôt.

BeforeAll {
    $repo = Split-Path -Path $PSScriptRoot -Parent
    Import-Module -Name (Join-Path -Path $repo -ChildPath 'src\WsCreator') -Force

    # dépôt minimal dans TestDrive : un fragment et une machine décrite comme il faut
    function New-TestRepo([string]$Name = 'box', [int]$Port = 2400, [string]$Hostname = $Name, [string]$User = 'dev') {
        New-Item -ItemType Directory -Force -Path "TestDrive:\cloud-config", "TestDrive:\modules", "TestDrive:\ssh", "TestDrive:\machines\$Name" | Out-Null
        Set-Content -Path 'TestDrive:\cloud-config\base.yaml' -Value '#cloud-config'
        Set-Content -Path 'TestDrive:\modules\agent.sh' -Value '#!/usr/bin/env bash'
        Set-Content -Path "TestDrive:\machines\$Name\machine.psd1" -Value @"
@{ BaseDistribution = 'Ubuntu-24.04'; Location = 'C:\x'; CloudConfig = @('base'); Modules = @('agent')
   Ssh = @{ Port = $Port; PublicKey = 'missing.pub' } }
"@
        Set-Content -Path "TestDrive:\machines\$Name\user-data.yaml" -Value @"
#cloud-config
users:
  - name: $User
write_files:
  - path: /etc/wsl.conf
    content: |
      [network]
      hostname=$Hostname
      [user]
      default=$User
"@
    }
}

Describe 'Get-UserDataValue' {
    It 'lit hostname, default et les utilisateurs de user-data.yaml' {
        InModuleScope WsCreator {
            $v = Get-UserDataValue "users:`n  - name: alice`n  - name: bob`n      hostname=m1`n      default=alice`n"
            $v.Hostname | Should -Be 'm1'
            $v.User | Should -Be 'alice'
            $v.Users | Should -Be @('alice', 'bob')
        }
    }
}

Describe 'Get-Machine' {
    It 'décrit agent-sandbox depuis examples\agent-sandbox' {
        # la clé publique de l'exemple, posée dans un ~\.ssh de test
        New-Item -ItemType Directory -Force -Path 'TestDrive:\ssh' | Out-Null
        (Get-Content (Join-Path $repo 'examples\agent-sandbox\user-data.yaml')) -match '^\s*- ssh-ed25519 ' |
            ForEach-Object { $_.Trim().TrimStart('- ') } | Set-Content 'TestDrive:\ssh\id_ed25519.pub'
        InModuleScope WsCreator -Parameters @{ Repo = $repo } {
            param($Repo)
            $saved = $script:MachinesDir, $script:SshDir
            $script:MachinesDir = Join-Path $Repo 'examples'
            $script:SshDir = Join-Path (Get-PSDrive TestDrive).Root 'ssh'
            try {
                $m = Get-Machine 'agent-sandbox'
                $m.Name | Should -Be 'agent-sandbox'
                $m.User | Should -Be 'dev'
                $m.CloudConfig | Should -Be @('base', 'mise', 'guard', 'podman', 'ssh')
                $m.Modules | Should -Be @('agent')
            } finally { $script:MachinesDir, $script:SshDir = $saved }
        }
    }

    Context 'machine de test' {
        BeforeEach { InModuleScope WsCreator { $script:Saved = $script:Root, $script:MachinesDir, $script:SshDir; $t = (Get-PSDrive TestDrive).Root; $script:Root = $t; $script:MachinesDir = Join-Path $t 'machines'; $script:SshDir = Join-Path $t 'ssh' } }
        AfterEach { InModuleScope WsCreator { $script:Root, $script:MachinesDir, $script:SshDir = $script:Saved } }

        It 'refuse un hostname différent du nom du dossier' {
            New-TestRepo -Name 'box' -Hostname 'other'
            InModuleScope WsCreator { { Get-Machine 'box' } | Should -Throw '*hostname=other*' }
        }

        It 'refuse un utilisateur par défaut absent de users' {
            New-TestRepo -Name 'box'
            (Get-Content 'TestDrive:\machines\box\user-data.yaml' -Raw) -replace 'default=dev', 'default=eve' |
                Set-Content 'TestDrive:\machines\box\user-data.yaml'
            InModuleScope WsCreator { { Get-Machine 'box' } | Should -Throw '*default=eve*' }
        }

        It 'refuse une clé publique SSH introuvable' {
            New-TestRepo -Name 'box'
            InModuleScope WsCreator { { Get-Machine 'box' } | Should -Throw '*public key not found*' }
        }

        It 'refuse un port SSH de user-data.yaml différent de machine.psd1' {
            New-TestRepo -Name 'box' -Port 2400
            Set-Content -Path 'TestDrive:\ssh\id_ed25519.pub' -Value 'ssh-ed25519 AAAAtest dev@test'
            Set-Content -Path 'TestDrive:\cloud-config\ssh.yaml' -Value '#cloud-config'
            (Get-Content 'TestDrive:\machines\box\machine.psd1' -Raw) -replace "CloudConfig = @\('base'\)", "CloudConfig = @('base', 'ssh')" -replace 'missing.pub', 'id_ed25519.pub' |
                Set-Content 'TestDrive:\machines\box\machine.psd1'
            Add-Content -Path 'TestDrive:\machines\box\user-data.yaml' -Value "      Port 2401`n      AllowUsers dev"
            InModuleScope WsCreator { { Get-Machine 'box' } | Should -Throw "*'Port 2400'*" }
        }
    }
}

Describe 'Select-MachinePart' {
    It 'garde tout sans -Only, et seulement les noms demandés avec' {
        InModuleScope WsCreator {
            $m = @{ Name = 'm'; CloudConfig = @('base', 'mise', 'ssh'); Modules = @('agent') }
            (Select-MachinePart $m @()).CloudConfig | Should -Be @('base', 'mise', 'ssh')
            $p = Select-MachinePart $m @('mise', 'agent')
            $p.CloudConfig | Should -Be @('mise')
            $p.Modules | Should -Be @('agent')
            { Select-MachinePart $m @('nope') } | Should -Throw "*'nope'*"
        }
    }
}

Describe 'Test-MachineConflict' {
    BeforeEach { InModuleScope WsCreator { $script:Saved = $script:Root, $script:MachinesDir, $script:SshDir; $t = (Get-PSDrive TestDrive).Root; $script:Root = $t; $script:MachinesDir = Join-Path $t 'machines'; $script:SshDir = Join-Path $t 'ssh' } }
    AfterEach { InModuleScope WsCreator { $script:Root, $script:MachinesDir, $script:SshDir = $script:Saved } }

    It 'refuse un port SSH déjà pris par une autre machine' {
        New-TestRepo -Name 'one' -Port 2400
        New-TestRepo -Name 'two' -Port 2400
        InModuleScope WsCreator {
            $m = @{ Name = 'one'; Ssh = @{ Port = 2400 }; Modules = @() }
            { Test-MachineConflict $m } | Should -Throw '*2400*two*'
        }
    }
}

Describe 'Get-SshHostConfig' {
    It 'passe par wsl.exe et nc vers le port de la machine' {
        InModuleScope WsCreator {
            $text = Get-SshHostConfig @{ Name = 'm'; User = 'dev'; Ssh = @{ Port = 2299; PublicKey = 'id_ed25519.pub' } }
            $text | Should -Match '(?m)^Host m$'
            $text | Should -Match 'User dev'
            $text | Should -Match 'IdentityFile ~/.ssh/id_ed25519\b'
            $text | Should -Match 'wsl.exe -d m --exec nc 127.0.0.1 2299'
        }
    }
}

Describe 'Structure du dépôt' {
    It '<_> est du cloud-config sans moteur de modèles' -ForEach @(
        Get-ChildItem -Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'src\WsCreator\cloud-config'), (Join-Path (Split-Path $PSScriptRoot -Parent) 'examples') -Recurse -Filter *.yaml |
            ForEach-Object { [IO.Path]::GetRelativePath((Split-Path $PSScriptRoot -Parent), $_.FullName) }
    ) {
        $text = Get-Content -Path (Join-Path $repo $_) -Raw
        $text | Should -Match '^#cloud-config'
        $text | Should -Not -Match '\{%|\{\{'
    }

    It 'les fichiers de files\ ont des fins de ligne Linux' {
        $crlf = Get-ChildItem -Path (Join-Path $repo 'src\WsCreator\files') -Recurse -File |
            Where-Object { (Get-Content -Path $_.FullName -Raw) -match "`r" }
        $crlf | Should -BeNullOrEmpty
    }

    It 'files\ ne vise aucun dossier personnel' {
        Get-ChildItem -Path (Join-Path $repo 'src\WsCreator\files') -Recurse -Directory |
            Where-Object { $_.FullName -match '\\(home|root)(\\|$)' } | Should -BeNullOrEmpty
    }

    # apply -Only guard joue cloud-init sans le fragment base : ce qui doit valoir à chaque passage
    # est dans la config système, copiée à chaque fois (une clé d'hôte régénérée casse ssh)
    It 'la config système de cloud-init garde les clés SSH et le nom d''hôte' {
        $cfg = Get-Content -Path (Join-Path $repo 'src\WsCreator\files\etc\cloud\cloud.cfg.d\99_zz-ws-creator.cfg') -Raw
        $cfg | Should -Match '(?m)^ssh_deletekeys: false'
        $cfg | Should -Match '(?m)^preserve_hostname: true'
        $cfg | Should -Match '(?m)^datasource_list: \[NoCloud, None\]'
    }
}
