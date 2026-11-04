# Côté Windows : un Host par machine, inclus depuis ~\.ssh\config. On entre dans la
# distro par wsl.exe + nc (démarre la distro à la demande, aucun port exposé).
function Get-SshHostConfig($m) {
    $identity = $m.Ssh.PublicKey -replace '\.pub$', ''
    @"
Host $($m.Name)
    User $($m.User)
    IdentityFile ~/.ssh/$identity
    IdentitiesOnly yes
    HostKeyAlias $($m.Name)
    UserKnownHostsFile ~/.ssh/ws-creator/$($m.Name).known_hosts
    StrictHostKeyChecking accept-new
    ProxyCommand C:/Windows/System32/wsl.exe -d $($m.Name) --exec nc 127.0.0.1 $($m.Ssh.Port)
"@ -replace "`r", ''   # le texte du script suit les fins de ligne de l'extraction git
}

function Set-SshHost($m) {
    $sshDir = Join-Path -Path $HOME -ChildPath '.ssh'
    $wsCreatorDir = Join-Path -Path $sshDir -ChildPath 'ws-creator'
    New-Item -ItemType Directory -Force -Path $wsCreatorDir | Out-Null
    # OpenSSH Windows refuse un fichier lisible par d'autres comptes : ACL privée,
    # comme ~\.ssh\config (utilisateur + SYSTEM, sans héritage du profil)
    icacls $wsCreatorDir /inheritance:r /grant:r "$env:USERDOMAIN\${env:USERNAME}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' /Q | Out-Null
    # les fichiers déjà présents reprennent l'ACL du dossier
    if (Get-ChildItem -Path $wsCreatorDir) { icacls "$wsCreatorDir\*" /reset /Q | Out-Null }
    Set-Content -Path (Join-Path -Path $wsCreatorDir -ChildPath "$($m.Name).conf") -Value (Get-SshHostConfig $m)
    $config = Join-Path -Path $sshDir -ChildPath 'config'
    $current = if (Test-Path -Path $config) { Get-Content -Path $config -Raw } else { '' }
    if ($current -notmatch '(?m)^Include ws-creator/\*\.conf') {
        Set-Content -Path $config -NoNewline -Value ("Include ws-creator/*.conf`n`n" + $current)
    }
}

function Remove-SshHost($m) {
    $wsCreatorDir = Join-Path -Path $HOME -ChildPath '.ssh\ws-creator'
    Remove-Item -Force -ErrorAction SilentlyContinue -Path `
        (Join-Path -Path $wsCreatorDir -ChildPath "$($m.Name).conf"),
        (Join-Path -Path $wsCreatorDir -ChildPath "$($m.Name).known_hosts")
}
