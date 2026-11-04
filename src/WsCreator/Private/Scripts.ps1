# Modules scripts (modules\<m>.sh) : ce que cloud-init n'exprime pas encore. Ils reçoivent
# les valeurs de machine.psd1 en variables WS_CREATOR_* (pas de secret : visibles dans ps).
function Get-ModuleVariable($m) {
    $vars = @("WS_CREATOR_NAME=$($m.Name)", "WS_CREATOR_USER=$($m.User)")
    if ($m.AgentInstructions) {
        $bytes = [IO.File]::ReadAllBytes((Join-Path -Path $m.Dir -ChildPath $m.AgentInstructions))
        $vars += "WS_CREATOR_AGENT_MD_B64=$([Convert]::ToBase64String($bytes))"
    }
    return $vars
}

# Le module part sur l'entrée standard, précédé de modules\lib.sh (fonctions communes)
function Invoke-Module($m, [string]$Script) {
    $vars = Get-ModuleVariable $m
    $lib = Get-Content -Path (Join-Path -Path $script:Root -ChildPath 'modules\lib.sh') -Raw
    ($lib + "`n" + (Get-Content -Path $Script -Raw)) |
        wsl -d $m.Name -u root --exec env @vars bash -c "tr -d '\r' | bash -s"
}

# Fragments par cloud-init, puis scripts, puis alias SSH Windows ; la distro est arrêtée à la fin
function Invoke-Machine($m, [string[]]$Only) {
    $parts = Select-MachinePart $m $Only
    if ($parts.CloudConfig) {
        Invoke-Step "cloud-init in $($m.Name): $($parts.CloudConfig -join ', ') + user-data.yaml" {
            Invoke-CloudInit $m $parts.CloudConfig
        }
    }
    foreach ($s in $parts.Modules) {
        $script = Join-Path -Path $script:Root -ChildPath "modules\$s.sh"
        Invoke-Step "Applying module $s in $($m.Name)" { Invoke-Module $m $script }
    }
    if ('ssh' -in $parts.CloudConfig) {
        Invoke-Step "Windows ssh config: Host $($m.Name) in ~\.ssh\ws-creator\$($m.Name).conf" { Set-SshHost $m }
    }
    Invoke-Step "stop containers + wsl --terminate $($m.Name)" { Stop-Distro $m }
}
