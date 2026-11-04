# Copie une arborescence de fichiers texte dans la distro, chemin relatif = destination
# (files\usr\local\bin\x -> /usr/local/bin/x). Le lien éventuel est remplacé, pas suivi.
# PowerShell ajoute une fin de ligne à ce qu'il envoie : head -c -1 la retire.
function Copy-FileTree($m, [string]$Source) {
    if (-not (Test-Path -Path $Source)) { return }
    foreach ($file in Get-ChildItem -Path $Source -Recurse -File) {
        $dest = '/' + ([IO.Path]::GetRelativePath($Source, $file.FullName) -replace '\\', '/')
        $dir = $dest.Substring(0, $dest.LastIndexOf('/'))
        Get-Content -Path $file.FullName -Raw |
            Invoke-Root $m "mkdir -p '$dir' && rm -f '$dest' && tr -d '\r' | head -c -1 > '$dest'"
    }
}

# Seed NoCloud, puis rejeu de cloud-init :
#   1. files\ et machines\<nom>\files\ copiés tels quels, /etc/ws-creator-profile ;
#   2. les fragments, puis user-data.yaml de la machine (en dernier : il complète), validés par
#      cloud-init schema et assemblés par make-mime ; meta-data : l'instance-id seul ;
#   3. clean, redémarrage, attente du résultat.
# cloud-init ajoute et ne retire jamais : retirer un droit ou changer l'isolation passe par
# purge puis new.
function Invoke-CloudInit($m, [string[]]$Fragments) {
    $PSNativeCommandUseErrorActionPreference = $false   # codes de sortie lus plus bas
    $seed = '/var/lib/cloud/seed/nocloud'
    $parts = '/var/lib/ws-creator/cloud-config'

    Copy-FileTree $m (Join-Path -Path $script:Root -ChildPath 'files')
    Copy-FileTree $m (Join-Path -Path $m.Dir -ChildPath 'files')
    $m.Name | Invoke-Root $m "tr -d '\r' > /etc/ws-creator-profile"

    Invoke-Root $m "rm -rf $parts && mkdir -p $parts $seed"
    $sources = @($Fragments | ForEach-Object { Join-Path -Path $script:Root -ChildPath "cloud-config\$_.yaml" }) + $m.UserData
    $names = @($Fragments) + 'user-data'
    $mime = @()
    for ($i = 0; $i -lt $sources.Count; $i++) {
        $part = '{0}/{1:d2}-{2}.yaml' -f $parts, $i, $names[$i]
        $mime += "-a ${part}:cloud-config"
        Get-Content -Path $sources[$i] -Raw | Invoke-Root $m "tr -d '\r' > $part"
        Invoke-Root $m "cloud-init schema -c $part >/dev/null" 2>&1 | Where-Object { $_ -notmatch 'datasource not detected' } |
            ForEach-Object { Write-Warning $_ }
        if ($LASTEXITCODE) { throw "cloud-init schema: $($sources[$i]) is not valid cloud-config" }
    }
    "instance-id: $($m.Name)" | Invoke-Root $m "tr -d '\r' > $seed/meta-data"
    Invoke-Root $m "cloud-init devel make-mime $($mime -join ' ') > $seed/user-data"
    if ($LASTEXITCODE) { throw "cloud-init devel make-mime failed in $($m.Name)" }

    # l'accueil d'Ubuntu (wsl-setup) pose ce marqueur au premier lancement interactif
    Invoke-Root $m 'rm -f /etc/cloud/cloud-init.disabled && cloud-init clean --logs'
    Stop-Distro $m
    $status = Invoke-Root $m 'cloud-init status --wait --format json' | ConvertFrom-Json
    Invoke-Root $m "grep -E 'WARNING|ERROR' /var/log/cloud-init.log || true" | ForEach-Object { Write-Warning $_ }
    if ($status.status -ne 'done') {
        throw "cloud-init in $($m.Name): $($status.status) ($($status.boot_status_code)), see /var/log/cloud-init.log"
    }
}
